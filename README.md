# Kubernetes Secret Experimentation
This repository is an experiment to better understand Kubernetes secrets and how
they can be dynamically managed (created, modified, added, deleted).

Important takeaways:
- Propagation delay when dynamically modifying, adding, and deleting secrets
- Kubernetes warns if you attempt to modify a secret that was created with the
`--from-*` command line options as these are considered "generated" resources
- If a POD mounts a secret then this POD will not be created until the secret
is created
- Secrets are not really "secret" as if you have permissions in `kubectl` to
see the secret then you can decode it with `base64`. So if you really want a
secret as a secret then you need to watch your `kubectl` permissions or use
some form of _vault_ utility.

## Change Propagation Delay
While changes to secrets are propagated to existing PODS, the change is not
propagated immediately. See reference in Kubernetes Documentation for further
information ([link](https://kubernetes.io/docs/concepts/configuration/secret/#mounted-secrets-are-updated-automatically])).

## Walkthrough

### Step 1 - Create Original Secret
```console
$ make step1
yq r secret.yml -j | jq ".data[\"secret.txt\"]=\"$(base64 original-secret.txt)\"" |  yq r -P - > original-secret.yml
kubectl apply -f ./original-secret.yml
secret/the-secret created
```

### Step 2 - Create POD that Uses Secret
```console
$ make step2
kubectl apply -f pod.yml
pod/tell-the-secret created
```

### Step 3 - View POD Logs
```console
$ make step3
kubectl logs --tail 10 pod/tell-the-secret
  mounts:
    - secret: "This is the original secret"
    - added: "cat: can't open '/var/my-secret/added-secret.txt': No such file or directory"
2020-08-12T17:43:34Z:
  environment:
    - secret: "This is the original secret"
    - added: ""
  mounts:
    - secret: "This is the original secret"
    - added: "cat: can't open '/var/my-secret/added-secret.txt': No such file or directory"
```

### Step 4 - Modify Secret
```console
$ make step4
yq r secret.yml -j | jq ".data[\"secret.txt\"]=\"$(base64 modified-secret.txt)\"" | yq r -P - > modified-secret.yml
kubectl apply -f ./modified-secret.yml
secret/the-secret configured
```

### Step 5 - View POD Logs
**NOTE:** _Because of the propagation delay for secret changes it may take
several minutes for the POD to "see" the change. you can use `make follow` to
"watch" the POD log as opposed to display that last 10 lines_

```console
$ make step5
kubectl logs --tail 10 pod/tell-the-secret
  mounts:
    - secret: "This is the modified secret"
    - added: "cat: can't open '/var/my-secret/added-secret.txt': No such file or directory"
2020-08-12T17:46:04Z:
  environment:
    - secret: "This is the original secret"
    - added: ""
  mounts:
    - secret: "This is the modified secret"
    - added: "cat: can't open '/var/my-secret/added-secret.txt': No such file or directory"
```

### Step 6 - Add Additional Secret
```console
$ make step6
yq r modified-secret.yml -j | jq ".data[\"added-secret.txt\"]=\"$(base64 added-secret.txt)\"" | yq r -P - > added-secret.yml
kubectl apply -f ./added-secret.yml
secret/the-secret configured
```

### Step 7 - View POD Logs
**NOTE:** _Because of the propagation delay for secret changes it may take
several minutes for the POD to "see" the change. you can use `make follow` to
"watch" the POD log as opposed to display that last 10 lines_

```console
$ make step7
kubectl logs --tail 10 pod/tell-the-secret
  mounts:
    - secret: "This is the modified secret"
    - added: "cat: can't open '/var/my-secret/added-secret.txt': No such file or directory"
2020-08-12T17:49:58Z:
  environment:
    - secret: "This is the original secret"
    - added: ""
  mounts:
    - secret: "This is the modified secret"
    - added: "This is the added secret"
```

### Step 8 - Delete Additional Secret
```console
$ make step8
yq r added-secret.yml -j | jq 'del(.data["secret.txt","added-secret.txt"])' | yq r -P - > deleted-secret.yml
kubectl apply -f ./deleted-secret.yml
secret/the-secret configured
```

### Step 9 - View POD Logs
**NOTE:** _Because of the propagation delay for secret changes it may take
several minutes for the POD to "see" the change. you can use `make follow` to
"watch" the POD log as opposed to display that last 10 lines_

```console
$ make step9
kubectl logs --tail 10 pod/tell-the-secret
  mounts:
    - secret: "This is the modified secret"
    - added: "This is the added secret"
2020-08-12T17:52:14Z:
  environment:
    - secret: "This is the original secret"
    - added: ""
  mounts:
    - secret: "cat: can't open '/var/my-secret/secret.txt': No such file or directory"
    - added: "cat: can't open '/var/my-secret/added-secret.txt': No such file or directory"
```

### Step 10 - Tear It All Down
```console
$ make step10
kubectl delete -f pod.yml || true
pod "tell-the-secret" deleted
kubectl delete secret the-secret || true
secret "the-secret" deleted
rm -f original-secret.yml modified-secret.yml added-secret.yml deleted-secret.yml
```
