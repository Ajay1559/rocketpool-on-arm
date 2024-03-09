== INSTALL LINUX ==
sudo dd bs=1M if=Downloads/ethonarm_rock5b_23.11.00.img of=/dev/sdb conv=fdatasync status=progress

== SSH TUNNELS ==
(so far nimbus is the same as lighthouse)
* https://linuxize.com/post/how-to-setup-ssh-tunneling/
* https://gist.github.com/drmalex07/c0f9304deea566842490
* `ss -lntp`
* Default Ports:
** beacon-client -> geth: The default port is 8551
** validator -> geth: The default port is 8545
** validator -> beacon: The default port is 5052
** beacon -> mev: The default port is 18550


== sed ==
* http://netjunky.net/sed-replace-path-with-slash-separators/
* https://unix.stackexchange.com/questions/268640/make-multiple-edits-with-a-single-call-to-sed

== bash ==
* https://stackoverflow.com/questions/64257286/giving-a-bash-script-the-option-to-accept-flags-like-a-command
* https://tldp.org/LDP/abs/html/complexfunct.html

== Rocket Pool ==
=== Configuring the Smartnode ===
* https://docs.rocketpool.net/guides/node/config-native.html

===Setting up Node Wallet & Starting Rocket Pool ===
* https://docs.rocketpool.net/guides/node/starting-rp.html

=== Updating the Smartnode Stack ===
* https://docs.rocketpool.net/guides/node/updates.html#updating-the-smartnode-stack

==== Useful Aliases (LINKz) ====
* GREP: https://stackoverflow.com/a/14871646
* disk usage: `du -hs * | sort -hr`
* list deleted file still on disk: `lsof | grep -c DEL`
* do I need a restart: `cat /var/run/reboot-required` & `cat /var/run/reboot-required.pkgs`