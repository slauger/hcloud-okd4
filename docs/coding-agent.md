# Deploy with a Coding Agent

Need an OKD or OpenShift test cluster? Copy the following prompt into your AI coding agent of choice. The agent asks for the distribution, version and size of the cluster as well as the credentials, shows the expected costs and waits for your confirmation before it creates any billable infrastructure.

```text
Deploy an OKD or OpenShift test cluster on Hetzner Cloud using
https://github.com/slauger/hcloud-okd4.

1. Clone the repository and read the README and docs/hetzner-specifics.md
   completely. Make sure docker, git, make, curl and jq are available.
2. Ask me what the cluster should look like, offering the options as a short
   multiple choice:
   - distribution: OKD or OCP (Red Hat OpenShift)
   - version: the latest stable release (determine it with `make latest_version`)
     or a specific version
   - number of worker nodes: 0 (single node cluster), 2 or a custom number
3. Ask me for everything else you need and do not have yet:
   - Hetzner Cloud API token of the project to deploy into
   - Cloudflare e-mail, API key and the zone ID of an existing zone that hosts the
     cluster domain (e.g. okd4.example.com)
   - Hetzner Object Storage bucket name, location and S3 access/secret key. Hetzner
     has no API for S3 credentials, so if I have none yet, tell me to create the
     bucket and the credentials in the Hetzner Console (see "Object Storage").
   - my SSH public key
   - for OCP only: the pull secret from https://console.redhat.com/openshift/install/pull-secret
   Store all secrets in a local env.sh (it is gitignored) and never commit them.
4. Set DEPLOYMENT_TYPE=okd or DEPLOYMENT_TYPE=ocp and TF_VAR_replicas_worker
   according to the parameters. For "latest", determine the version with
   `make latest_version` (for OCP, set OCP_RELEASE_CHANNEL to the newest
   stable-4.x channel first). Fetch the binaries and build the toolbox image. Run
   all further make targets inside the toolbox container non-interactively:
   docker run --rm -v "$PWD:/workspace" -e <every variable from env.sh> <image>
   make <target>, and pass DEPLOYMENT_TYPE to every make call.
5. Create install-config.yaml from the README example. metadata.name plus baseDomain
   must result in exactly the cluster domain (TF_VAR_dns_domain), and machineNetwork
   has to be the private node subnet (TF_VAR_subnet_cidr, default 192.168.254.0/24).
   For OCP use the real pull secret instead of the placeholder.
6. Generate manifests and ignition configs and build the CoreOS image with Packer.
   The ignition certificates expire after 24 hours, so the bootstrap has to be
   completed within that time, otherwise regenerate them.
7. Before creating any billable infrastructure, show me what will be created and
   the expected costs (see "Costs"), and wait for my confirmation.
8. Follow the Quick Start: deploy with BOOTSTRAP=true, wait for the bootstrap to
   complete, remove the bootstrap node, approve CSRs until all nodes are Ready and
   wait for the installation to complete. See "Duration" for the expected timing.
   Run the wait targets in the background, they take longer than most command
   timeouts. If one of them times out, simply start it again, that is harmless.
   Meanwhile, check progress with oc (nodes, csr, clusteroperators).
9. A single master restarts etcd and the API server several times during the
   installation, short API outages are expected. If a step fails or stalls for
   more than 15 minutes, find the root cause (nodes, cluster operators, pod logs,
   load balancer health checks) instead of blindly retrying. The nodes do not
   accept SSH from the internet: use oc adm node-logs / oc debug node, or add a
   temporary hcloud firewall rule for my IP only and remove it afterwards.
10. Verify the result: all nodes Ready with their private IPs, all cluster operators
   Available and not Degraded, the console answers with HTTP 200.
11. When finished, give me the console URL, the paths to the kubeconfig and the
    kubeadmin password, the hourly costs, and remind me that `make destroy`
    removes the cluster. Never run `make destroy` without asking me first.
```

The prompt relies on the [README](../README.md), in particular the sections "Costs" and "Duration", and on [Hetzner Cloud Specifics](hetzner-specifics.md).
