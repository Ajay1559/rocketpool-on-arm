== INSTALL LINUX ==
sudo dd bs=1M if=Downloads/ethonarm_rock5b_23.11.00.img of=/dev/sdb conv=fdatasync status=progress

== SSH TUNNELS ==
* https://linuxize.com/post/how-to-setup-ssh-tunneling/
* https://gist.github.com/drmalex07/c0f9304deea566842490
* `ss -lntp`
* Default Ports:
** beacon-client -> geth: The default port is 8551
** validator -> geth: The default port is 8545
** validator -> beacon: The default port is 5052
** beacon -> mev: The default port is 18550
