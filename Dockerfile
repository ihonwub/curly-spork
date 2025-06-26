# Use a build argument to set the base image color
ARG COLOR=yellow
FROM quay.io/openshiftdemos/rollouts-demo:${COLOR}

# Metadata
LABEL color="${COLOR}"
