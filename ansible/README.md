# Provisioning

Instructions to provision a remote environment.

## Pre-requirements

#### 1. Install ansible requirements on the local machine
```
$ ansible-galaxy install -r  ansible/requirements.yml
```


#### 2. Python must be installed on the remote system
```
# apt-get install python
```

#### 3. The remote system must have a `deploy` user, with sudo privileges.

You must also give this user a password, keep it handy.

```
# adduser deploy
# usermod -aG sudo deploy
```

You must be able to login with this user with ssh keys.

On the local machine generate an ssh key:
```
ssh-keygen -t rsa -C "covfefe@app.portosummerofcode.com"
```

Add the public key to `/home/deploy/.ssh/authorized_keys` on the remote machine.

You can use this `.ssh/config` snippet to associate a particular ssh key with a remote host on the local machine.

```
host app.portosummerofcode.com
    Hostname app.portosummerofcode.com
    User deploy
    IdentityFile ~/.ssh/id_rsa_psc
```

Test using `ssh deploy@app.portosummerofcode.com "whoami"` or something.

#### 4. Generate a diffie-hellman key-exchange parameters file

On the remote machine:
```
# openssl dhparam -out /etc/nginx/dhparam.pem 2048
```

#### 5. Add a deploy key to the remote server

## Provisioning

#### 0. A catch-22

Here's a tricky deal: The provisioning tasks will install certbot (letsencrypt) on the remote machine, but for all the tasks to succeed in one go, the certificate files must already exist. My not-so-fancy solution to this is to run the provisioning tasks until they fail, generate the certificates, then run the provisioning tasks again.

#### 1. Run the provisioning tasks

On the local machine:

```
$ ansible-playbook --inventory-file=ansible/inventory -l app.portosummerofcode.com --ask-sudo-pass ansible/production.yml
```

You will be prompted to input the deploy user password. I told you to keep it handy.

#### 2. Generate ssl certificates.

On the remote machine, as root:

```
# letsencrypt certonly --agree-tos --email info@portosummerofcode.com --standalone -d api.portosummerofcode.com
```

This will start a stand-alone http server on the remote host, so the host can prove control of the domain. See more in https://letsencrypt.org/how-it-works/. In the end, we get ssl certificates. Yay!

#### Run the provisioning tasks again


# Wot

ssh-keygen -t rsa -C "deploy@api.portosummerofcode.com"
