---
title: Reducing noise in my OpenTofu/Terraform provider plans
description: How I reduced unnecessary "known after apply" entries for attributes not explicitly managed by configuration.
date: 2026-09-30
tags:
- Go
- OpenTofu
- Terraform
---

## Introduction

Anyone who uses OpenTofu or Terraform extensively knows that "known after apply"
entries can make a plan output frustratingly cluttered. These entries are normal
during resource creation or after import, but they become distracting during
unrelated updates.

A little over a year ago, [I began writing an OpenTofu/Terraform provider for
Forgejo]({{< ref "blog/terraform/forgejo.md" >}}). It is the second provider I
have written and I did not know all the tricks (I most certainly still do not!),
but something clicked last month: I finally understood how to patch my code to
make unmanaged attributes less noisy when updating.

## Example of the problem

Most OpenTofu/Terraform providers want to enforce the configuration of the used
resources as tightly as possible, and it often makes sense to do so. However,
that model is less suitable for Forgejo, where users and other administrators
also make changes through the webui.

I always wanted my OpenTofu/Terraform provider to silently ignore whatever the
admin chooses to manually manage, enforcing only the attributes admins
explicitly configure, but it was surprisingly difficult to express that
distinction in code. Here is what we had in the plan before when for example
changing the description of a user:

``` text
# forgejo_user.test will be updated in-place
~ resource "forgejo_user" "test" {
    ~ active            = true -> (known after apply)
    ~ created_at        = "2026-09-29T10:21:02+02:00" -> (known after apply)
    ~ description       = "test user2" -> "test user3"
      name              = "test"
      ... # a few more known after apply
  }
```

The `created_at` attribute is unmanaged by our code, so I wanted to no longer
see it in any update! Same for all the repository units that an admin may wish
users to manage themselves. If we want to enforce the presence of the Pull
Requests unit but let admins turn on and off the wiki in the webui, then we
should never see anything about wiki in our plans.

## How to do this

There are three things we need to get right:
- setting the correct plan modifiers in the schema,
- not feeding zero values to API requests where we want a nil value,
- merge planned values with the update response to remove the noise.

### Schema plan modifiers

The resource schema needs to have the `UseStateForUnknown()` plan modifier for
the attributes with optional enforcement, for example:

``` go
func (d *UserResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"active": schema.BoolAttribute{
				Computed:            true,
				MarkdownDescription: "Whether the user is active or not. If unset, the server value will be left as is.",
				Optional:            true,
				PlanModifiers: []planmodifier.Bool{
					boolplanmodifier.UseStateForUnknown(),
				},
			},
			"description": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "A description string. If unset, the server value will be left as is.",
				Optional:            true,
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.UseStateForUnknown(),
				},
			},
            [...]
```

### Do not feed unwanted zero values to API calls

I introduced a few helpers to handle unknown values the way I want them when
building the request struct values that are fed to API calls:

``` go
// boolPointerIfKnown returns a pointer to the bool value, or nil when the value
// is null or unknown so that it is omitted from API request payloads.
//
// It differs from the SDK's types.Bool.ValueBoolPointer() in the unknown case:
// that method returns a pointer to false, which would override the server's
// default.
func boolPointerIfKnown(v types.Bool) *bool {
	if v.IsUnknown() || v.IsNull() {
		return nil
	}
	return v.ValueBoolPointer()
}

// stringPointerIfKnown returns a pointer to the string value, or nil when the
// value is null or unknown so that it is omitted from API request payloads.
//
// It differs from the SDK's types.String.ValueStringPointer() in the unknown
// case: that method returns a pointer to "", which would override the server's
// default.
func stringPointerIfKnown(v types.String) *string {
	if v.IsUnknown() || v.IsNull() {
		return nil
	}
	return v.ValueStringPointer()
}
```

Here is an example showing these helpers in action:

``` go
func userUpdateRequest(data *UserResourceModel, sendPassword bool) *client.UserUpdateRequest {
	loginName := data.LoginName.ValueString()
	if loginName == "" {
		loginName = data.Login.ValueString()
	}
	request := client.UserUpdateRequest{
		Active:             boolPointerIfKnown(data.Active),
		Admin:              boolPointerIfKnown(data.IsAdmin),
		Description:        stringPointerIfKnown(data.Description),
		Email:              data.Email.ValueStringPointer(),
		FullName:           stringPointerIfKnown(data.FullName),
		Location:           stringPointerIfKnown(data.Location),
		LoginName:          loginName,
		MustChangePassword: boolPointerIfKnown(data.MustChangePassword),
		ProhibitLogin:      boolPointerIfKnown(data.ProhibitLogin),
		Pronouns:           stringPointerIfKnown(data.Pronouns),
		Restricted:         boolPointerIfKnown(data.Restricted),
		SourceId:           data.SourceId.ValueInt64(),
		Visibility:         data.Visibility.ValueString(),
		Website:            stringPointerIfKnown(data.Website),
	}
	if sendPassword && !data.Password.IsNull() && !data.Password.IsUnknown() {
		request.Password = data.Password.ValueString()
	}
	return &request
}
```

### Merge planned values with the update response

I introduced another helper:

``` go
// knownOr returns the planned value when it is known, and the server value
// otherwise. It is meant to be used after an update API call: values that were
// planned are kept as is (avoiding "inconsistent result after apply" errors on
// incomplete API responses), while values that were unknown at plan time are
// filled in from the server response.
func knownOr[T attr.Value](planned T, server T) T {
	if planned.IsUnknown() {
		return server
	}
	return planned
}
```

Here is a usage example that shows proper response handling:

``` go
func (d *UserResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plannedData UserResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plannedData)...)
	var stateData UserResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &stateData)...)
	if resp.Diagnostics.HasError() {
		return
	}
	passwordChanged := !plannedData.Password.Equal(stateData.Password)
	if plannedData.LoginName.IsUnknown() || plannedData.LoginName.IsNull() {
		plannedData.LoginName = stateData.LoginName
	}
	user, err := d.client.UserUpdate(
		ctx,
		stateData.Login.ValueString(),
		userUpdateRequest(&plannedData, passwordChanged))
	if err != nil {
		resp.Diagnostics.AddError("UpdateUser", fmt.Sprintf("failed to update user: %s", err))
		return
	}
	var serverData UserResourceModel
	populateUserResourceModel(&serverData, user)
	plannedData.Active = knownOr(plannedData.Active, serverData.Active)
	plannedData.Created = knownOr(plannedData.Created, serverData.Created)
	plannedData.Description = knownOr(plannedData.Description, serverData.Description)
	plannedData.Email = knownOr(plannedData.Email, serverData.Email)
	plannedData.FullName = knownOr(plannedData.FullName, serverData.FullName)
	plannedData.HtmlUrl = knownOr(plannedData.HtmlUrl, serverData.HtmlUrl)
	plannedData.Id = knownOr(plannedData.Id, serverData.Id)
	plannedData.IsAdmin = knownOr(plannedData.IsAdmin, serverData.IsAdmin)
	plannedData.Location = knownOr(plannedData.Location, serverData.Location)
	plannedData.LoginName = knownOr(plannedData.LoginName, serverData.LoginName)
	plannedData.Login = knownOr(plannedData.Login, serverData.Login)
	plannedData.ProhibitLogin = knownOr(plannedData.ProhibitLogin, serverData.ProhibitLogin)
	plannedData.Pronouns = knownOr(plannedData.Pronouns, serverData.Pronouns)
	plannedData.Restricted = knownOr(plannedData.Restricted, serverData.Restricted)
	plannedData.SourceId = knownOr(plannedData.SourceId, serverData.SourceId)
	plannedData.Visibility = knownOr(plannedData.Visibility, serverData.Visibility)
	plannedData.Website = knownOr(plannedData.Website, serverData.Website)
	resp.Diagnostics.Append(resp.State.Set(ctx, &plannedData)...)
}
```

## Conclusion

With these helpers, techniques, and some programming discipline, I managed to
get what appears to be the exact behavior I wanted out of my OpenTofu/Terraform
provider for Forgejo.

As far as I can tell this behaves correctly even on concurrent changes (tofu
plan, a user clicks to change some unenforced setting, then tofu apply), but I
will be on the lookout for consistency bugs. If you are reading me and have
terraform provider development expertise, I would love your review or input on
this method I settled on!
