---
name: Switch to Pre-built Devcon Image
about: Proposal to use pre-built devcon Docker image
title: "Switch to pre-built devcon Docker image"
labels: enhancement, docker
assignees: ""
---

## Description

Replace the current custom Docker build with the pre-built `devcon` image from GitHub Container Registry to improve build efficiency and consistency.

### Proposed Change

Use the following pre-built image:

```docker
ghcr.io/entelecheia/devcon:0.4.1-ubuntu-22.04
```

### Benefits

- Faster deployment/setup time by eliminating build step
- Consistent environment across deployments
- Reduced build complexity
- Leverages official pre-built image

### Implementation Tasks

- [ ] Update Docker configuration to use `ghcr.io/entelecheia/devcon:0.4.1-ubuntu-22.04`
- [ ] Remove custom build instructions
- [ ] Test functionality with pre-built image
- [ ] Update documentation to reflect the change

## Additional Notes

This change will help streamline our development environment setup while maintaining consistency with the official devcon releases.
