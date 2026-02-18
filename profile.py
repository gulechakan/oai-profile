#!/usr/bin/env python

import os

import geni.portal as portal
import geni.rspec.pg as rspec
import geni.rspec.igext as IG
import geni.rspec.emulab.pnext as PN
import geni.rspec.emulab.spectrum as spectrum


tourDescription = """
### OAI 5G E2E Low Latency 

This profile instantiates an experiment for testing OAI 5G end-to-end low latency service.

- A d430 compute node to host the OAI 5G CN, OAI 5G RAN, and NR UE(s).

"""

tourInstructions = """

Startup scripts will still be running when your experiment becomes ready.  Watch the "Startup" column on the "List View" tab for your experiment and wait until all of the compute nodes show "Finished" before proceeding.

After all startup scripts have finished...

On `oai-host`, open a terminal session via SSH, or using the shell option for that node in the portal.

"""

UBUNTU_IMG = "urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU22-64-STD"
COMP_MANAGER_ID = "urn:publicid:IDN+emulab.net+authority+cm"


pc = portal.Context()

node_types = [
    ("d430", "Emulab, d430"),
    ("d710", "Emulab, d710"),
]

pc.defineParameter(
    name="cn_repo_url", 
    description="GitHub repo for OAI CN5G", 
    typ=portal.ParameterType.STRING,
    defaultValue="https://github.com/gulechakan/oai-cn5g-fed"
    )

pc.defineParameter(
    name="cn_repo_branch", 
    description="Branch or commit hash", 
    typ=portal.ParameterType.STRING, 
    defaultValue="master"
    )

pc.defineParameter(
    name="oai_nodetype",
    description="Type of compute node to use for OAI node (if included)",
    typ=portal.ParameterType.STRING,
    defaultValue=node_types[1],
    legalValues=node_types
)

params = pc.bindParameters()
pc.verifyParameters()
request = pc.makeRequestRSpec()

# OAI Host
oai_node = request.RawPC("oai-host")
oai_node.component_manager_id = COMP_MANAGER_ID
oai_node.hardware_type = params.oai_nodetype
oai_node.disk_image = UBUNTU_IMG

# CN5G Startup Script
setup_cmd = 'bash /local/repository/bin/setup.sh {} {}'.format(params.cn_repo_url, params.cn_repo_branch)
oai_node.addService(rspec.Execute(shell="bash", command=setup_cmd))

# # NearRT-RIC Startup Script
# deploy_nearrt_ric = "/local/repository/bin/deploy-nearrt_ric.sh {} {}".format(params.nearrt_ric_repo_url, params.nearrt_ric_repo_branch)
# oai_node.addService(rspec.Execute(shell="bash", command=deploy_nearrt_ric))

# Tour
tour = IG.Tour()
tour.Description(IG.Tour.MARKDOWN, tourDescription)
tour.Instructions(IG.Tour.MARKDOWN, tourInstructions)
request.addTour(tour)

pc.printRequestRSpec(request)