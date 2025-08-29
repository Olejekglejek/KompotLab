TASK [talos-apps/adguard : Apply AdGuard Kubernetes manifests using Kustomize] ***
[WARNING]: Platform linux on host localhost is using the discovered Python
interpreter at /usr/bin/python3.11, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.18/reference_appendices/interpreter_discovery.html for more information.
fatal: [localhost]: FAILED! => changed=false
  ansible_facts:
    discovered_interpreter_python: /usr/bin/python3.11
  cmd:
  - kubectl
  - apply
  - -k
  - .
  delta: '0:00:00.363830'
  end: '2025-08-20 21:58:58.715214'
  msg: non-zero return code
  rc: 1
  start: '2025-08-20 21:58:58.351384'
  stderr: 'error: error validating ".": error validating data: failed to download openapi: Get "http://localhost:8080/openapi/v2?timeout=32s": dial tcp [::1]:8080: connect: connection refused; if you choose to ignore these errors, turn validation off with --validate=false'
  stderr_lines: <omitted>
  stdout: ''
  stdout_lines: <omitted>

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0

Need to pass talos config and kubectl config in the dockerfile
