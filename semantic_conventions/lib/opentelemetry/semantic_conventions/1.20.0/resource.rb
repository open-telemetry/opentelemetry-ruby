# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../1.10.0/resource'

module OpenTelemetry
  module SemanticConventions_1_20_0 # rubocop:disable Naming/ClassAndModuleCamelCase
    # https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/
    module Resource
      def self.const_missing(const_name)
        attribute_name = OpenTelemetry::SemanticConventions_1_10_0::Trace.const_get(const_name)
        super(const_name) unless attribute_name

        warn "#{const_name} is deprecated."
        const_set(const_name, attribute_name)
        attribute_name
      end

      # The ARN of an [ECS cluster](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html)
      AWS_ECS_CLUSTER_ARN = 'aws.ecs.cluster.arn'

      # The Amazon Resource Name (ARN) of an [ECS container instance](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_instances.html)
      AWS_ECS_CONTAINER_ARN = 'aws.ecs.container.arn'

      # The [launch type](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html) for an ECS task
      AWS_ECS_LAUNCHTYPE = 'aws.ecs.launchtype'

      # The ARN of an [ECS task definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
      AWS_ECS_TASK_ARN = 'aws.ecs.task.arn'

      # The task definition family this task definition is a member of
      AWS_ECS_TASK_FAMILY = 'aws.ecs.task.family'

      # The revision for this task definition
      AWS_ECS_TASK_REVISION = 'aws.ecs.task.revision'

      # The ARN of an EKS cluster
      AWS_EKS_CLUSTER_ARN = 'aws.eks.cluster.arn'

      # The Amazon Resource Name(s) (ARN) of the AWS log group(s)
      #
      # @note See the [log group ARN format documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/iam-access-control-overview-cwl.html#CWL_ARN_Format)
      AWS_LOG_GROUP_ARNS = 'aws.log.group.arns'

      # The name(s) of the AWS log group(s) an application is writing to
      #
      # @note Multiple log groups must be supported for cases like multi-container applications, where a single application has sidecar containers, and each write to their own log group
      AWS_LOG_GROUP_NAMES = 'aws.log.group.names'

      # The ARN(s) of the AWS log stream(s)
      #
      # @note See the [log stream ARN format documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/iam-access-control-overview-cwl.html#CWL_ARN_Format). One log group can contain several log streams, so these ARNs necessarily identify both a log group and a log stream
      AWS_LOG_STREAM_ARNS = 'aws.log.stream.arns'

      # The name(s) of the AWS log stream(s) an application is writing to
      AWS_LOG_STREAM_NAMES = 'aws.log.stream.names'

      # Array of brand name and version separated by a space
      #
      # @note This value is intended to be taken from the [UA client hints API](https://wicg.github.io/ua-client-hints/#interface) (`navigator.userAgentData.brands`)
      BROWSER_BRANDS = 'browser.brands'

      # Preferred language of the user using the browser
      #
      # @note This value is intended to be taken from the Navigator API `navigator.language`
      BROWSER_LANGUAGE = 'browser.language'

      # A boolean that is true if the browser is running on a mobile device
      #
      # @note This value is intended to be taken from the [UA client hints API](https://wicg.github.io/ua-client-hints/#interface) (`navigator.userAgentData.mobile`). If unavailable, this attribute SHOULD be left unset
      BROWSER_MOBILE = 'browser.mobile'

      # The platform on which the browser is running
      #
      # @note This value is intended to be taken from the [UA client hints API](https://wicg.github.io/ua-client-hints/#interface) (`navigator.userAgentData.platform`). If unavailable, the legacy `navigator.platform` API SHOULD NOT be used instead and this attribute SHOULD be left unset in order for the values to be consistent.
      #  The list of possible values is defined in the [W3C User-Agent Client Hints specification](https://wicg.github.io/ua-client-hints/#sec-ch-ua-platform). Note that some (but not all) of these values can overlap with values in the [`os.type` and `os.name` attributes](./os.md). However, for consistency, the values in the `browser.platform` attribute should capture the exact value that the user agent provides
      BROWSER_PLATFORM = 'browser.platform'

      # The cloud account ID the resource is assigned to
      CLOUD_ACCOUNT_ID = 'cloud.account.id'

      # Cloud regions often have multiple, isolated locations known as zones to increase availability. Availability zone represents the zone where the resource is running
      #
      # @note Availability zones are called "zones" on Alibaba Cloud and Google Cloud
      CLOUD_AVAILABILITY_ZONE = 'cloud.availability_zone'

      # The cloud platform in use
      #
      # @note The prefix of the service SHOULD match the one specified in `cloud.provider`
      CLOUD_PLATFORM = 'cloud.platform'

      # Name of the cloud provider
      CLOUD_PROVIDER = 'cloud.provider'

      # The geographical region the resource is running
      #
      # @note Refer to your provider's docs to see the available regions, for example [Alibaba Cloud regions](https://www.alibabacloud.com/help/doc-detail/40654.htm), [AWS regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/), [Azure regions](https://azure.microsoft.com/en-us/global-infrastructure/geographies/), [Google Cloud regions](https://cloud.google.com/about/locations), or [Tencent Cloud regions](https://www.tencentcloud.com/document/product/213/6091)
      CLOUD_REGION = 'cloud.region'

      # Cloud provider-specific native identifier of the monitored cloud resource (e.g. an [ARN](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) on AWS, a [fully qualified resource ID](https://learn.microsoft.com/en-us/rest/api/resources/resources/get-by-id) on Azure, a [full resource name](https://cloud.google.com/apis/design/resource_names#full_resource_name) on GCP)
      #
      # @note On some cloud providers, it may not be possible to determine the full ID at startup,
      #  so it may be necessary to set `cloud.resource_id` as a span attribute instead.
      #  
      #  The exact value to use for `cloud.resource_id` depends on the cloud provider.
      #  The following well-known definitions MUST be used if you set this attribute and they apply:
      #  
      #  * **AWS Lambda:** The function [ARN](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html).
      #    Take care not to use the "invoked ARN" directly but replace any
      #    [alias suffix](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html)
      #    with the resolved function version, as the same runtime instance may be invokable with
      #    multiple different aliases.
      #  * **GCP:** The [URI of the resource](https://cloud.google.com/iam/docs/full-resource-names)
      #  * **Azure:** The [Fully Qualified Resource ID](https://docs.microsoft.com/en-us/rest/api/resources/resources/get-by-id) of the invoked function,
      #    *not* the function app, having the form
      #    `/subscriptions/<SUBSCIPTION_GUID>/resourceGroups/<RG>/providers/Microsoft.Web/sites/<FUNCAPP>/functions/<FUNC>`.
      #    This means that a span attribute MUST be used, as an Azure function app can host multiple functions that would usually share
      #    a TracerProvider
      CLOUD_RESOURCE_ID = 'cloud.resource_id'

      # Container ID. Usually a UUID, as for example used to [identify Docker containers](https://docs.docker.com/engine/reference/run/#container-identification). The UUID might be abbreviated
      CONTAINER_ID = 'container.id'

      # Name of the image the container was built on
      CONTAINER_IMAGE_NAME = 'container.image.name'

      # Container image tag
      CONTAINER_IMAGE_TAG = 'container.image.tag'

      # Container name used by container runtime
      CONTAINER_NAME = 'container.name'

      # The container runtime managing this container
      CONTAINER_RUNTIME = 'container.runtime'

      # Name of the [deployment environment](https://en.wikipedia.org/wiki/Deployment_environment) (aka deployment tier)
      DEPLOYMENT_ENVIRONMENT = 'deployment.environment'

      # A unique identifier representing the device
      #
      # @note The device identifier MUST only be defined using the values outlined below. This value is not an advertising identifier and MUST NOT be used as such. On iOS (Swift or Objective-C), this value MUST be equal to the [vendor identifier](https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor). On Android (Java or Kotlin), this value MUST be equal to the Firebase Installation ID or a globally unique UUID which is persisted across sessions in your application. More information can be found [here](https://developer.android.com/training/articles/user-data-ids) on best practices and exact implementation details. Caution should be taken when storing personal data or anything which can identify a user. GDPR and data protection laws may apply, ensure you do your own due diligence
      DEVICE_ID = 'device.id'

      # The name of the device manufacturer
      #
      # @note The Android OS provides this field via [Build](https://developer.android.com/reference/android/os/Build#MANUFACTURER). iOS apps SHOULD hardcode the value `Apple`
      DEVICE_MANUFACTURER = 'device.manufacturer'

      # The model identifier for the device
      #
      # @note It's recommended this value represents a machine readable version of the model identifier rather than the market or consumer-friendly name of the device
      DEVICE_MODEL_IDENTIFIER = 'device.model.identifier'

      # The marketing name for the device model
      #
      # @note It's recommended this value represents a human readable version of the device model rather than a machine readable alternative
      DEVICE_MODEL_NAME = 'device.model.name'

      # The execution environment ID as a string, that will be potentially reused for other invocations to the same function/function version
      #
      # @note * **AWS Lambda:** Use the (full) log stream name
      FAAS_INSTANCE = 'faas.instance'

      # The amount of memory available to the serverless function converted to Bytes
      #
      # @note It's recommended to set this attribute since e.g. too little memory can easily stop a Java AWS Lambda function from working correctly. On AWS Lambda, the environment variable `AWS_LAMBDA_FUNCTION_MEMORY_SIZE` provides this information (which must be multiplied by 1,048,576)
      FAAS_MAX_MEMORY = 'faas.max_memory'

      # The name of the single function that this runtime instance executes
      #
      # @note This is the name of the function as configured/deployed on the FaaS
      #  platform and is usually different from the name of the callback
      #  function (which may be stored in the
      #  [`code.namespace`/`code.function`](../../trace/semantic_conventions/span-general.md#source-code-attributes)
      #  span attributes).
      #  
      #  For some cloud providers, the above definition is ambiguous. The following
      #  definition of function name MUST be used for this attribute
      #  (and consequently the span name) for the listed cloud providers/products:
      #  
      #  * **Azure:**  The full name `<FUNCAPP>/<FUNC>`, i.e., function app name
      #    followed by a forward slash followed by the function name (this form
      #    can also be seen in the resource JSON for the function).
      #    This means that a span attribute MUST be used, as an Azure function
      #    app can host multiple functions that would usually share
      #    a TracerProvider (see also the `cloud.resource_id` attribute)
      FAAS_NAME = 'faas.name'

      # The immutable version of the function being executed
      #
      # @note Depending on the cloud provider and platform, use:
      #  
      #  * **AWS Lambda:** The [function version](https://docs.aws.amazon.com/lambda/latest/dg/configuration-versions.html)
      #    (an integer represented as a decimal string).
      #  * **Google Cloud Run:** The [revision](https://cloud.google.com/run/docs/managing/revisions)
      #    (i.e., the function name plus the revision suffix).
      #  * **Google Cloud Functions:** The value of the
      #    [`K_REVISION` environment variable](https://cloud.google.com/functions/docs/env-var#runtime_environment_variables_set_automatically).
      #  * **Azure Functions:** Not applicable. Do not set this attribute
      FAAS_VERSION = 'faas.version'

      # Unique identifier for the application
      HEROKU_APP_ID = 'heroku.app.id'

      # Commit hash for the current release
      HEROKU_RELEASE_COMMIT = 'heroku.release.commit'

      # Time and date the release was created
      HEROKU_RELEASE_CREATION_TIMESTAMP = 'heroku.release.creation_timestamp'

      # The CPU architecture the host system is running on
      HOST_ARCH = 'host.arch'

      # Unique host ID. For Cloud, this must be the instance_id assigned by the cloud provider. For non-containerized systems, this should be the `machine-id`. See the table below for the sources to use to determine the `machine-id` based on operating system
      HOST_ID = 'host.id'

      # VM image ID. For Cloud, this value is from the provider
      HOST_IMAGE_ID = 'host.image.id'

      # Name of the VM image or OS install the host was instantiated from
      HOST_IMAGE_NAME = 'host.image.name'

      # The version string of the VM image as defined in [Version Attributes](README.md#version-attributes)
      HOST_IMAGE_VERSION = 'host.image.version'

      # Name of the host. On Unix systems, it may contain what the hostname command returns, or the fully qualified hostname, or another name specified by the user
      HOST_NAME = 'host.name'

      # Type of host. For Cloud, this must be the machine type
      HOST_TYPE = 'host.type'

      # The name of the cluster
      K8S_CLUSTER_NAME = 'k8s.cluster.name'

      # The name of the Container from Pod specification, must be unique within a Pod. Container runtime usually uses different globally unique name (`container.name`)
      K8S_CONTAINER_NAME = 'k8s.container.name'

      # Number of times the container was restarted. This attribute can be used to identify a particular container (running or stopped) within a container spec
      K8S_CONTAINER_RESTART_COUNT = 'k8s.container.restart_count'

      # The name of the CronJob
      K8S_CRONJOB_NAME = 'k8s.cronjob.name'

      # The UID of the CronJob
      K8S_CRONJOB_UID = 'k8s.cronjob.uid'

      # The name of the DaemonSet
      K8S_DAEMONSET_NAME = 'k8s.daemonset.name'

      # The UID of the DaemonSet
      K8S_DAEMONSET_UID = 'k8s.daemonset.uid'

      # The name of the Deployment
      K8S_DEPLOYMENT_NAME = 'k8s.deployment.name'

      # The UID of the Deployment
      K8S_DEPLOYMENT_UID = 'k8s.deployment.uid'

      # The name of the Job
      K8S_JOB_NAME = 'k8s.job.name'

      # The UID of the Job
      K8S_JOB_UID = 'k8s.job.uid'

      # The name of the namespace that the pod is running in
      K8S_NAMESPACE_NAME = 'k8s.namespace.name'

      # The name of the Node
      K8S_NODE_NAME = 'k8s.node.name'

      # The UID of the Node
      K8S_NODE_UID = 'k8s.node.uid'

      # The name of the Pod
      K8S_POD_NAME = 'k8s.pod.name'

      # The UID of the Pod
      K8S_POD_UID = 'k8s.pod.uid'

      # The name of the ReplicaSet
      K8S_REPLICASET_NAME = 'k8s.replicaset.name'

      # The UID of the ReplicaSet
      K8S_REPLICASET_UID = 'k8s.replicaset.uid'

      # The name of the StatefulSet
      K8S_STATEFULSET_NAME = 'k8s.statefulset.name'

      # The UID of the StatefulSet
      K8S_STATEFULSET_UID = 'k8s.statefulset.uid'

      # Human readable (not intended to be parsed) OS version information, like e.g. reported by `ver` or `lsb_release -a` commands
      OS_DESCRIPTION = 'os.description'

      # Human readable operating system name
      OS_NAME = 'os.name'

      # The operating system type
      OS_TYPE = 'os.type'

      # The version string of the operating system as defined in [Version Attributes](../../resource/semantic_conventions/README.md#version-attributes)
      OS_VERSION = 'os.version'

      # Deprecated, use the `otel.scope.name` attribute
      #
      # @deprecated 
      OTEL_LIBRARY_NAME = 'otel.library.name'

      # Deprecated, use the `otel.scope.version` attribute
      #
      # @deprecated 
      OTEL_LIBRARY_VERSION = 'otel.library.version'

      # The name of the instrumentation scope - (`InstrumentationScope.Name` in OTLP)
      OTEL_SCOPE_NAME = 'otel.scope.name'

      # The version of the instrumentation scope - (`InstrumentationScope.Version` in OTLP)
      OTEL_SCOPE_VERSION = 'otel.scope.version'

      # The command used to launch the process (i.e. the command name). On Linux based systems, can be set to the zeroth string in `proc/[pid]/cmdline`. On Windows, can be set to the first parameter extracted from `GetCommandLineW`
      PROCESS_COMMAND = 'process.command'

      # All the command arguments (including the command/executable itself) as received by the process. On Linux-based systems (and some other Unixoid systems supporting procfs), can be set according to the list of null-delimited strings extracted from `proc/[pid]/cmdline`. For libc-based executables, this would be the full argv vector passed to `main`
      PROCESS_COMMAND_ARGS = 'process.command_args'

      # The full command used to launch the process as a single string representing the full command. On Windows, can be set to the result of `GetCommandLineW`. Do not set this if you have to assemble it just for monitoring; use `process.command_args` instead
      PROCESS_COMMAND_LINE = 'process.command_line'

      # The name of the process executable. On Linux based systems, can be set to the `Name` in `proc/[pid]/status`. On Windows, can be set to the base name of `GetProcessImageFileNameW`
      PROCESS_EXECUTABLE_NAME = 'process.executable.name'

      # The full path to the process executable. On Linux based systems, can be set to the target of `proc/[pid]/exe`. On Windows, can be set to the result of `GetProcessImageFileNameW`
      PROCESS_EXECUTABLE_PATH = 'process.executable.path'

      # The username of the user that owns the process
      PROCESS_OWNER = 'process.owner'

      # Parent Process identifier (PID)
      PROCESS_PARENT_PID = 'process.parent_pid'

      # Process identifier (PID)
      PROCESS_PID = 'process.pid'

      # An additional description about the runtime of the process, for example a specific vendor customization of the runtime environment
      PROCESS_RUNTIME_DESCRIPTION = 'process.runtime.description'

      # The name of the runtime of this process. For compiled native binaries, this SHOULD be the name of the compiler
      PROCESS_RUNTIME_NAME = 'process.runtime.name'

      # The version of the runtime of this process, as returned by the runtime without modification
      PROCESS_RUNTIME_VERSION = 'process.runtime.version'

      # The string ID of the service instance
      #
      # @note MUST be unique for each instance of the same `service.namespace,service.name` pair (in other words `service.namespace,service.name,service.instance.id` triplet MUST be globally unique). The ID helps to distinguish instances of the same service that exist at the same time (e.g. instances of a horizontally scaled service). It is preferable for the ID to be persistent and stay the same for the lifetime of the service instance, however it is acceptable that the ID is ephemeral and changes during important lifetime events for the service (e.g. service restarts). If the service has no inherent unique ID that can be used as the value of this attribute it is recommended to generate a random Version 1 or Version 4 RFC 4122 UUID (services aiming for reproducible UUIDs may also use Version 5, see RFC 4122 for more recommendations)
      SERVICE_INSTANCE_ID = 'service.instance.id'

      # Logical name of the service
      #
      # @note MUST be the same for all instances of horizontally scaled services. If the value was not specified, SDKs MUST fallback to `unknown_service:` concatenated with [`process.executable.name`](process.md#process), e.g. `unknown_service:bash`. If `process.executable.name` is not available, the value MUST be set to `unknown_service`
      SERVICE_NAME = 'service.name'

      # A namespace for `service.name`
      #
      # @note A string value having a meaning that helps to distinguish a group of services, for example the team name that owns a group of services. `service.name` is expected to be unique within the same namespace. If `service.namespace` is not specified in the Resource then `service.name` is expected to be unique for all services that have no explicit namespace defined (so the empty/unspecified namespace is simply one more valid namespace). Zero-length namespace string is assumed equal to unspecified namespace
      SERVICE_NAMESPACE = 'service.namespace'

      # The version string of the service API or implementation
      SERVICE_VERSION = 'service.version'

      # The version string of the auto instrumentation agent, if used
      TELEMETRY_AUTO_VERSION = 'telemetry.auto.version'

      # The language of the telemetry SDK
      TELEMETRY_SDK_LANGUAGE = 'telemetry.sdk.language'

      # The name of the telemetry SDK as defined above
      TELEMETRY_SDK_NAME = 'telemetry.sdk.name'

      # The version string of the telemetry SDK
      TELEMETRY_SDK_VERSION = 'telemetry.sdk.version'

      # Full user-agent string provided by the browser
      #
      # @note The user-agent value SHOULD be provided only from browsers that do not have a mechanism to retrieve brands and platform individually from the User-Agent Client Hints API. To retrieve the value, the legacy `navigator.userAgent` API can be used
      USER_AGENT_ORIGINAL = 'user_agent.original'

      # Additional description of the web engine (e.g. detailed version and edition information)
      WEBENGINE_DESCRIPTION = 'webengine.description'

      # The name of the web engine
      WEBENGINE_NAME = 'webengine.name'

      # The version of the web engine
      WEBENGINE_VERSION = 'webengine.version'

    end
  end
end