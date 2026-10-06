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
   - for OCP only: architecture amd64 (CPX servers) or arm64 (CAX servers, about a
     third of the costs)
   - control plane: 1 master or 3 masters (highly available)
   - number of worker nodes: 0 (masters run all workloads), 2 or a custom number
   - if there are workers: the same server type as the masters or smaller workers
     with 8 GB RAM (cpx32, or cax21 for arm64), see "Costs" in the README
   - DNS: Cloudflare (records are managed automatically) or my own DNS (I create
     the records myself, see "DNS" in the README)
3. Ask me for everything else you need and do not have yet:
   - Hetzner Cloud API token of the project to deploy into
   - the cluster domain (e.g. okd4.example.com)
   - for Cloudflare DNS: e-mail, API key and the zone ID of an existing zone that
     hosts the cluster domain
   - Hetzner Object Storage bucket name, location and S3 access/secret key. Hetzner
     has no API for S3 credentials, so if I have none yet, tell me to create the
     bucket and the credentials in the Hetzner Console (see "Object Storage").
   - my SSH public key
   - a pull secret from https://console.redhat.com/openshift/install/pull-secret,
     required for OCP, optional for OKD (it enables the Red Hat operator catalogs)
   Store all secrets in a local env.sh (it is gitignored) and never commit them.
4. Set DEPLOYMENT_TYPE=okd or DEPLOYMENT_TYPE=ocp, TF_VAR_replicas_master,
   TF_VAR_replicas_worker, TF_VAR_dns_provider (cloudflare or none), ARCH
   (amd64 or arm64) and for smaller workers TF_VAR_worker_server_type according
   to my answers. For OCP, set OCP_RELEASE_CHANNEL to
   the newest stable-4.x channel before running `make latest_version`. Run `make fetch` for the chosen
   release and pull the toolbox image ghcr.io/slauger/hcloud-okd4:latest. Run all
   further make targets inside the toolbox non-interactively, in the architecture
   of this machine: docker run --rm --platform linux/<arch of this machine>
   -v "$PWD:/workspace" -e <every variable from env.sh> <image> make <target>,
   and pass DEPLOYMENT_TYPE, OPENSHIFT_RELEASE and ARCH to every make call.
5. Create install-config.yaml from the README example. metadata.name plus baseDomain
   must result in exactly the cluster domain (TF_VAR_dns_domain), and machineNetwork
   has to be the private node subnet (TF_VAR_subnet_cidr, default 192.168.254.0/24),
   controlPlane.replicas has to match TF_VAR_replicas_master, and for arm64 set
   architecture: arm64 for controlPlane and compute.
   Use my pull secret if I provided one, otherwise (OKD only) the placeholder.
6. Generate manifests and ignition configs and build the CoreOS image with Packer.
   The ignition certificates expire after 24 hours, so the bootstrap has to be
   completed within that time, otherwise regenerate them.
7. With my own DNS: tell me which records to create before the deployment
   (api-int and the node records, see "DNS" in the README) and wait until they
   resolve. After the infrastructure is created, tell me the remaining records
   from the Terraform output dns_records.
8. Before creating any billable infrastructure, show me what will be created and
   the expected costs (see "Costs"), and wait for my confirmation.
9. Follow the Quick Start: deploy with BOOTSTRAP=true, wait for the bootstrap to
   complete, remove the bootstrap node, approve CSRs until all nodes are Ready and
   wait for the installation to complete. See "Duration" for the expected timing.
   Run the wait targets in the background, they take longer than most command
   timeouts. If one of them times out, simply start it again, that is harmless.
   Meanwhile, check progress with oc (nodes, csr, clusteroperators).
10. A single master restarts etcd and the API server several times during the
   installation, short API outages are expected. If a step fails or stalls for
   more than 15 minutes, find the root cause (nodes, cluster operators, pod logs,
   load balancer health checks) instead of blindly retrying. The nodes do not
   accept SSH from the internet: use oc adm node-logs / oc debug node, or add a
   temporary hcloud firewall rule for my IP only and remove it afterwards.
11. Verify the result: all nodes Ready with their private IPs, all cluster operators
   Available and not Degraded, the console answers with HTTP 200.
12. When finished, give me the console URL, the paths to the kubeconfig and the
    kubeadmin password, the hourly costs, and remind me that `make destroy`
    removes the cluster. Never run `make destroy` without asking me first.
```

The prompt relies on the [README](../README.md), in particular the sections "Costs" and "Duration", and on [Hetzner Cloud Specifics](hetzner-specifics.md).
