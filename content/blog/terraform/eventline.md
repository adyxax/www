---
title: Writing a terraform provider for eventline
description: A great piece of software is missing a terraform provider, let's write it
date: 2023-08-04
tags:
- eventline
- terraform
---

## Introduction

I have been using terraform to manage infrastructure both personnaly and at work for several years now and I know this tool quite well. I have been searching for an excuse to write a terraform provider for quite some time in order to dive deeper into terraform and I finally realised that I had just such excuse!

I started using [eventline](https://www.exograd.com/products/eventline/) when it was released a year ago and have been very happy with it. Turns out I could benefit from a terraform provider to provision identities or jobs when deploying new hosts, so here I go!

## Writing a terraform provider

### Where to start

The recommended way is to fork the [terraform provider scaffolding framework](https://github.com/hashicorp/terraform-provider-scaffolding-framework) repository from Hashicorp. This is what I did, but it came with some frustration. Hashicorp recently deprecated another way of developing terraform providers called SDKv2, thereform the big downside is that almost all the examples, blog posts or existing providers you would like to take inspiration from are all using the old sdk!

Without good examples, you are left with reading the documentation (which I found a bit lacking) and reading the sources of hashicorp's framework and libraries (which thanks to go's "boringness" is surprisingly possible, even enjoyable).

### The project name

I did not find it explicitely documented so here it is for you: you MUST name your provider's repository `terraform-provider-something`, otherwise the builtin CI from the framework repository will not work with some very cryptic errors!

### Terraform types wrapping

One thing that puzzled me a bit was how to make terraform's schema types work with go types. When writing your datasources and resources, you define your types like this simple:
```go
type ProjectResourceModel struct {
	Id   types.String `tfsdk:"id"`
	Name types.String `tfsdk:"name"`
}
```

This go type is associated with a schema function that will look like:
```go
func (r *ProjectResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "Project Id",
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.UseStateForUnknown(),
				},
			},
			"name": schema.StringAttribute{
				MarkdownDescription: "Project name",
				Required: true,
			},
		},
		MarkdownDescription: "Eventline project resource",
	}
}
```

To use this resource, the user of this terraform provider wlil provide a `name` and will get back an `id`. To use the name in your code, you will need to do:
```go
var data *ProjectResourceModel
resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
if resp.Diagnostics.HasError() {
	return
}
name := data.Name.ValueString() //get the go string out of the terraform resource schema
```

To provision the Id:
```go
	data.Id = types.StringValue(id) // wraps the go string into the right type for terraform resource schema
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
```

### Schema with nested list attributes

The examples form hashicorp all reference list with simple types. If you want to better describe your resources and datasources, you will need to write your lists in this manner:
```go
func (d *ProjectsDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"elements": schema.ListNestedAttribute{
				Computed:            true,
				MarkdownDescription: "The list of projects.",
				NestedObject: schema.NestedAttributeObject{
					Attributes: map[string]schema.Attribute{
						"id": schema.StringAttribute{
							Computed:            true,
							MarkdownDescription: "The identifier of the project.",
						},
						"name": schema.StringAttribute{
							Computed:            true,
							MarkdownDescription: "The name of the project.",
						},
					},
				},
			},
		},
		MarkdownDescription: "Use this data source to retrieve information about existing eventline projects.",
	}
}
```

### Testing your work with a provider override

In order to develop comfortably your provider, you will need a `~/.terraformrc` file that looks like the following:
```hcl
plugin_cache_dir   = "$HOME/.terraform.d/plugin-cache"
disable_checkpoint = true

provider_installation {
  dev_overrides {
      "adyxax/eventline" = "/home/julien/.go/bin/"
  }

  # For all other providers, install them directly from their origin provider
  # registries as normal. If you omit this, Terraform will _only_ use
  # the dev_overrides block, and so no other providers will be available.
  direct {}
}
```

Use the binary subfolder of your $GOPATH and this will work. When you `go install` your provider, the resulting binary will get copied there and be picked up by terraform on each `plan` or `apply`. Yes: the neat thing is that you do not need to run `init` constantly!

### Provider documentation

The provider's documentation can be generated with `go generate`. It will use the `MarddownDescription` attributes you defined in your schema descriptions so make those good entries. As the name suggest, you can use multiline markdown so go crazy with it!

Another piece to know about is the `examples` folder in your repository. If you give it a structure like:
```
examples/
├── data-sources
│   ├── eventline_identities
│   │   └── data-source.tf
│   ├── eventline_jobs
│   │   └── data-source.tf
│   ├── eventline_project
│   │   └── data-source.tf
│   └── eventline_projects
│       └── data-source.tf
├── provider
│   └── provider.tf
├── README.md
└── resources
    └── eventline_project
        ├── import.sh
        └── resource.tf
```

Then your objects documentation will get augmented with useful examples for the users of your provider.

## Conclusion

Writing a terraform provider is a lot of fun, I recommend it! If you have a piece of software that you wish had a terraform provider, know that it is not that hard to make it a reality.

Here is [the repository of my eventline provider](https://git.adyxax.org/adyxax/terraform-provider-eventline/) for reference and here is [the terraform provider's page](https://registry.terraform.io/providers/adyxax/eventline/latest/docs).
