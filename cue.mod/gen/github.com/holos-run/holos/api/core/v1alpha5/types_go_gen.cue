// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/holos-run/holos/api/core/v1alpha5

// Package core contains schemas for a [Platform] and [BuildPlan].  Holos takes
// a [Platform] as input, then iterates over each [Component] to produce a
// [BuildPlan].  Holos processes the [BuildPlan] to produce fully rendered
// manifests, each an [Artifact].
package core

// BuildPlan represents an implementation of the [rendered manifest pattern].
// Holos processes a BuildPlan to produce one or more [Artifact] output files.
// BuildPlan artifact files usually contain Kubernetes manifests, but they may
// have any content.
//
// A BuildPlan usually produces two artifacts.  One artifact contains a manifest
// of resources.  A second artifact contains a GitOps resource to manage the
// first, usually an ArgoCD Application resource.
//
// Holos uses CUE to construct a BuildPlan.  A future enhancement will support
// user defined executables providing a BuildPlan to Holos in the style of an
// [external credential provider].
//
// [rendered manifest pattern]: https://akuity.io/blog/the-rendered-manifests-pattern
// [external credential provider]: https://github.com/kubernetes/enhancements/blob/313ad8b59c80819659e1fbf0f165230f633f2b22/keps/sig-auth/541-external-credential-providers/README.md
#BuildPlan: {
	// Kind represents the type of the resource.
	kind: string & "BuildPlan" @go(Kind)

	// APIVersion represents the versioned schema of the resource.
	apiVersion: string & (string | *"v1alpha5") @go(APIVersion)

	// Metadata represents data about the resource such as the Name.
	metadata: #Metadata @go(Metadata)

	// Spec specifies the desired state of the resource.
	spec: #BuildPlanSpec @go(Spec)
}

// BuildPlanSpec represents the specification of the [BuildPlan].
#BuildPlanSpec: {
	// Artifacts represents the artifacts for holos to build.
	artifacts: [...#Artifact] @go(Artifacts,[]Artifact)

	// Disabled causes the holos cli to disregard the build plan.
	disabled?: bool @go(Disabled)
}

// Artifact represents one fully rendered manifest produced by a [Transformer]
// sequence, which transforms a [Generator] collection.  A [BuildPlan] produces
// an [Artifact] collection.
//
// Each Artifact produces one manifest file artifact.  Generator Output values
// are used as Transformer Inputs.  The Output field of the final [Transformer]
// should have the same value as the Artifact field.
//
// When there is more than one [Generator] there must be at least one
// [Transformer] to combine outputs into one Artifact.  If there is a single
// Generator, it may directly produce the Artifact output.
//
// An Artifact is processed concurrently with other artifacts in the same
// [BuildPlan].  An Artifact should not use an output from another Artifact as
// an input.  Each [Generator] may also run concurrently.  Each [Transformer] is
// executed sequentially starting after all generators have completed.
//
// Output fields are write-once.  It is an error for multiple Generators or
// Transformers to produce the same Output value within the context of a
// [BuildPlan].
#Artifact: {
	artifact?: #FilePath @go(Artifact)
	generators?: [...#Generator] @go(Generators,[]Generator)
	transformers?: [...#Transformer] @go(Transformers,[]Transformer)
	validators?: [...#Validator] @go(Validators,[]Validator)
	skip?: bool @go(Skip)
}

// Generator generates Kubernetes resources.  [Helm] and [Resources] are the
// most commonly used, often paired together to mix-in resources to an
// unmodified Helm chart.  A simple [File] generator is also available for use
// with the [Kustomize] transformer.
//
// Each Generator in an [Artifact] must have a distinct Output value for a
// [Transformer] to reference.
//
//  1. [Resources] - Generates resources from CUE code.
//  2. [Helm] - Generates rendered yaml from a [Chart].
//  3. [File] - Generates data by reading a file from the component directory.
#Generator: {
	// Kind represents the kind of generator.  Must be Resources, Helm, or File.
	kind: string & ("Resources" | "Helm" | "File") @go(Kind)

	// Output represents a file for a Transformer or Artifact to consume.
	output: #FilePath @go(Output)

	// Resources generator. Ignored unless kind is Resources.  Resources are
	// stored as a two level struct.  The top level key is the Kind of resource,
	// e.g. Namespace or Deployment.  The second level key is an arbitrary
	// InternalLabel.  The third level is a map[string]any representing the
	// Resource.
	resources?: #Resources @go(Resources)

	// Helm generator. Ignored unless kind is Helm.
	helm?: #Helm @go(Helm)

	// File generator. Ignored unless kind is File.
	file?: #File @go(File)
}

// Resource represents one kubernetes api object.
#Resource: {...}

// Resources represents Kubernetes resources.  Most commonly used to mix
// resources into the [BuildPlan] generated from CUE, but may be generated from
// elsewhere.
#Resources: {[string]: [string]: #Resource}

// File represents a simple single file copy [Generator].  Useful with a
// [Kustomize] [Transformer] to process plain manifest files stored in the
// component directory.  Multiple File generators may be used to transform
// multiple resources.
#File: {
	// Source represents a file sub-path relative to the component path.
	source: #FilePath @go(Source)
}

// Helm represents a [Chart] manifest [Generator].
#Helm: {
	// Chart represents a helm chart to manage.
	chart: #Chart @go(Chart)

	// Values represents values for holos to marshal into values.yaml when
	// rendering the chart.
	values: #Values @go(Values)

	// EnableHooks enables helm hooks when executing the `helm template` command.
	enableHooks?: bool @go(EnableHooks)

	// Namespace represents the helm namespace flag
	namespace?: string @go(Namespace)

	// APIVersions represents the helm template --api-versions flag
	apiVersions?: [...string] @go(APIVersions,[]string)

	// KubeVersion represents the helm template --kube-version flag
	kubeVersion?: string @go(KubeVersion)
}

// Values represents [Helm] Chart values generated from CUE.
#Values: {...}

// Chart represents a [Helm] Chart.
#Chart: {
	// Name represents the chart name.
	name: string @go(Name)

	// Version represents the chart version.
	version: string @go(Version)

	// Release represents the chart release when executing helm template.
	release: string @go(Release)

	// Repository represents the repository to fetch the chart from.
	repository?: #Repository @go(Repository)
}

// Repository represents a [Helm] [Chart] repository.
//
// The Auth field is useful to configure http basic authentication to the Helm
// repository.  Holos gets the username and password from the environment
// variables represented by the Auth field.
#Repository: {
	name:  string @go(Name)
	url:   string @go(URL)
	auth?: #Auth  @go(Auth)
}

// Auth represents environment variable names containing auth credentials.
#Auth: {
	username: #AuthSource @go(Username)
	password: #AuthSource @go(Password)
}

// AuthSource represents a source for the value of an [Auth] field.
#AuthSource: {
	value?:   string @go(Value)
	fromEnv?: string @go(FromEnv)
}

// Transformer combines multiple inputs from prior [Generator] or [Transformer]
// outputs into one output.  [Kustomize] is the most commonly used transformer.
// A simple [Join] is also supported for use with plain manifest files.
//
//  1. [Kustomize] - Patch and transform the output from prior generators or
//     transformers.  See [Introduction to Kustomize].
//  2. [Join] - Concatenate multiple prior outputs into one output.
//
// [Introduction to Kustomize]: https://kubectl.docs.kubernetes.io/guides/config_management/introduction/
#Transformer: {
	// Kind represents the kind of transformer. Must be Kustomize, or Join.
	kind: string & ("Kustomize" | "Join") @go(Kind)

	// Inputs represents the files to transform. The Output of prior Generators
	// and Transformers.
	inputs: [...#FilePath] @go(Inputs,[]FilePath)

	// Output represents a file for a subsequent Transformer or Artifact to
	// consume.
	output: #FilePath @go(Output)

	// Kustomize transformer. Ignored unless kind is Kustomize.
	kustomize?: #Kustomize @go(Kustomize)

	// Join transformer. Ignored unless kind is Join.
	join?: #Join @go(Join)
}

// Join represents a [Transformer] using [bytes.Join] to concatenate multiple
// inputs into one output with a separator.  Useful for combining output from
// [Helm] and [Resources] together into one [Artifact] when [Kustomize] is
// otherwise unnecessary.
//
// [bytes.Join]: https://pkg.go.dev/bytes#Join
#Join: {
	separator?: string @go(Separator)
}

// Kustomize represents a kustomization [Transformer].
#Kustomize: {
	// Kustomization represents the decoded kustomization.yaml file
	kustomization: #Kustomization @go(Kustomization)

	// Files holds file contents for kustomize, e.g. patch files.
	files?: #FileContentMap @go(Files)
}

// Kustomization represents a kustomization.yaml file for use with the
// [Kustomize] [Transformer].  Untyped to avoid tightly coupling holos to
// kubectl versions which was a problem for the Flux maintainers.  Type checking
// is expected to happen in CUE against the kubectl version the user prefers.
#Kustomization: {...}

// FileContentMap represents a mapping of file paths to file contents.
#FileContentMap: {[string]: #FileContent}

// FilePath represents a file path.
#FilePath: string

// FileContent represents file contents.
#FileContent: string

// Validator validates files.  Useful to validate an [Artifact] prior to writing
// it out to the final destination.  Holos may execute validators concurrently.
// See the [validators] tutorial for an end to end example.
//
// [validators]: https://holos.run/docs/v1alpha5/tutorial/validators/
#Validator: {
	// Kind represents the kind of transformer. Must be Kustomize, or Join.
	kind: string & "Command" @go(Kind)

	// Inputs represents the files to validate.  Usually the final Artifact.
	inputs: [...#FilePath] @go(Inputs,[]FilePath)

	// Command represents a validation command.  Ignored unless kind is Command.
	command?: #Command @go(Command)
}

// Command represents a command vetting one or more artifacts.  Holos appends
// fully qualified input file paths to the end of the args list, then executes
// the command.  Inputs are written into a temporary directory prior to
// executing the command and removed afterwards.
#Command: {
	args?: [...string] @go(Args,[]string)
}

// InternalLabel is an arbitrary unique identifier internal to holos itself.
// The holos cli is expected to never write a InternalLabel value to rendered
// output files, therefore use a InternalLabel when the identifier must be
// unique and internal.  Defined as a type for clarity and type checking.
#InternalLabel: string

// Kind is a discriminator. Defined as a type for clarity and type checking.
#Kind: string

// Metadata represents data about the resource such as the Name.
#Metadata: {
	// Name represents the resource name.
	name: string @go(Name)

	// Labels represents a resource selector.
	labels?: {[string]: string} @go(Labels,map[string]string)

	// Annotations represents arbitrary non-identifying metadata.  For example
	// holos uses the `cli.holos.run/description` annotation to log resources in a
	// user customized way.
	annotations?: {[string]: string} @go(Annotations,map[string]string)
}

// Platform represents a platform to manage.  A Platform specifies a [Component]
// collection and integrates the components together into a holistic platform.
// Holos iterates over the [Component] collection producing a [BuildPlan] for
// each, which holos then executes to render manifests.
//
// Inspect a Platform resource holos would process by executing:
//
//	cue export --out yaml ./platform
#Platform: {
	// Kind is a string value representing the resource.
	kind: string & "Platform" @go(Kind)

	// APIVersion represents the versioned schema of this resource.
	apiVersion: string & (string | *"v1alpha5") @go(APIVersion)

	// Metadata represents data about the resource such as the Name.
	metadata: #Metadata @go(Metadata)

	// Spec represents the platform specification.
	spec: #PlatformSpec @go(Spec)
}

// PlatformSpec represents the platform specification.
#PlatformSpec: {
	// Components represents a collection of holos components to manage.
	components: [...#Component] @go(Components,[]Component)
}

// Component represents the complete context necessary to produce a [BuildPlan]
// from a path containing parameterized CUE configuration.
#Component: {
	// Name represents the name of the component. Injected as the tag variable
	// "holos_component_name".
	name: string @go(Name)

	// Path represents the path of the component relative to the platform root.
	// Injected as the tag variable "holos_component_path".
	path: string @go(Path)

	// WriteTo represents the holos render component --write-to flag.  If empty,
	// the default value for the --write-to flag is used.
	writeTo?: string @go(WriteTo)

	// Parameters represent user defined input variables to produce various
	// [BuildPlan] resources from one component path.  Injected as CUE @tag
	// variables.  Parameters with a "holos_" prefix are reserved for use by the
	// Holos Authors.  Multiple environments are a prime example of an input
	// parameter that should always be user defined, never defined by Holos.
	parameters?: {[string]: string} @go(Parameters,map[string]string)

	// Labels represent selector labels for the component.  Copied to the
	// resulting BuildPlan.
	labels?: {[string]: string} @go(Labels,map[string]string)

	// Annotations represents arbitrary non-identifying metadata.  Use the
	// `cli.holos.run/description` to customize the log message of each BuildPlan.
	annotations?: {[string]: string} @go(Annotations,map[string]string)
}
