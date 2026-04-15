# Post Installation Steps

After successfully installing nexus you can access it on the port `8081` by default

## Change the admin password

* Click in signin on top right and enter the username as admin
* Password is located on nexus server at path `/opt/sonatype-work/nexus3/admin.password`

 ```sh
 cat /opt/sonatype-work/nexus3/admin.password
 ```

* Paste the copied password to sigin page
* Proceed to next steps by changing the admin password
* Disable anonymous access if you dont want strangers to view/acces your repositories.