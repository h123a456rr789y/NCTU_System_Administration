###### tags: `SA`
# SA hw5

## NIS Client
[Ref Link1](https://blog.zespre.com/2014/12/25/freebsd-nis-nfs.html)
[Ref Link2](http://wiki.weithenn.org/cgi-bin/wiki.pl?NIS-Network_Information_Service)
- Modify `/etc/rc.conf` and start the services
```
wireguard_enable="YES"
wireguard_interfaces="wg0″
rpcbind_enable="YES"
nis_client_enable="YES"
nisdomainname="savpn.nctu.me"
nis_client_flags="-s -m -S savpn.nctu.me,10.113.0.254″
```
- Modify `/etc/rc.d/ypbind` to start wiregard before binding
```
## uncomment this line
REQUIRE: ypserv wireguard
```

- Roboot to apply the modifications
- Use following yp command to test
```
% ypwhich
10.113.0.254

% ypwhich -x
"passwd" is an alias for "passwd.byname"
"master.passwd" is an alias for "master.passwd.byname"
"shadow" is an alias for "shadow.byname"
"group" is an alias for "group.byname"
"networks" is an alias for "networks.byaddr"
"hosts" is an alias for "hosts.byaddr"
"protocols" is an alias for "protocols.bynumber"
"services" is an alias for "services.byname"
"aliases" is an alias for "mail.aliases"
"ethers" is an alias for "ethers.byname"

% ypcat passwd
nisuser1:*:1005:1005:nisuser1:/net/home/nisuser1:/usr/local/bin/bash
nisuser2:*:1006:1006:nisuser2:/net/home/nisuser2:/usr/local/bin/bash
nisuser3:*:1007:1007:nisuser3:/net/home/nisuser3:/usr/local/bin/bash
```

- Let the Nis user accounts to login in to your server  
    - vipw 修改 /etc/master.passwd 將非系統本身的使用者移除(我沒移除)，並在檔案最後加入下列一行：`+:::::::::`
    - vigr編輯 /etc/group，將非系統本身的使用者移除(我沒移除)，並加入這一行：
    `+:*::`
```
$ sudo cp /etc/master.passwd /var/yp
$ sudo cp /etc/group /var/yp/
```
- Set home directory of NIS user to be '/net/home/<username>' when they login 
```
sudo pw usermod nisuser1 -m /net/home/nisuser1
sudo pw usermod nisuser2 -m /net/home/nisuser2
sudo pw usermod nisuser3 -m /net/home/nisuser3
```


## NFS Client
[NFS Ref](http://wiki.weithenn.org/cgi-bin/wiki.pl?NFS-Unix_%E9%96%93%E7%9A%84%E7%B6%B2%E8%B7%AF%E8%8A%B3%E9%84%B0)
[Autofs](https://nixbsd.wordpress.com/2014/12/28/freebsd-nfs-automount-with-autofs/)
[NFS Handbook](https://www.freebsd.org/doc/handbook/network-nfs.html#network-autofs)
- Modify `/etc/rc.conf` and add the services
```
nfs_client_enable="YES"
```
- Test the NFS server mounting resources
```
% showmount -a 10.113.0.254
All mount points on 10.113.0.254:
10.113.0.123:/net/data
10.113.0.123:/net/home
10.113.0.130:/net/data
10.113.0.133:/net/home
10.113.0.35:/net/home
10.113.0.46:/net/home
10.113.0.67:/net/data
10.113.0.67:/net/home
10.113.0.77:/net/data
10.113.0.77:/net/home
10.113.0.93:/net/data
10.113.0.93:/net/home
10.113.0.98:/net/home
10.113.37.128:/net/data
10.113.37.128:/net/home

% showmount -d 10.113.0.254
Directories on 10.113.0.254:
/net/data
/net/home

% showmount -e 10.113.0.254
Exports list on 10.113.0.254:
/net/home                          10.113.0.0 
/net/data                          10.113.0.0 

```
- How to mount directories from NFS server **(可以不用做這個階段 直接跳去auto mounting)**
    - 執行 mount_nfs 指令時加上參數 -s 如此一來當 NFS Client 掛載 (mount) 失敗幾次之後便不再嘗試去 mount
    - 執行 mount_nfs 指令時加上參數 -i 為允許使用 Ctrl+C 來中斷掛載 (mount)
    - 執行如何指令將 NFS Server (10.113.0.254) 所分享的資料夾 (/net/data,/net/home) 手動掛載到自已的資料夾（我掛到 /net/home與/net/data 自己建立的資料夾) 之下
    
```
mount_nfs -s -i 10.113.0.254:/net/home /net/home
mount_nfs -s -i 10.113.0.254:/net/data /net/data
```

- Auto Mounting
[direct and indirect map ref](https://www.freebsd.org/cgi/man.cgi?query=auto_master&sektion=5&fbclid=IwAR2HSHAmq8boOMJfhCW24V0YqN3Wz7NYVDIZ6eVDK3m0EjRbBrhR00-PYLc)
    - AMD(automounter daemon)
        - For more details plz look up the Ref link
    - Autofs
        - modify`/etc/rc.conf`:
        `autofs_enable=”YES”`
        ~~- indirect map (don't use this)
        1.modify `/etc/auto_master`:
        `/net        /etc/auto.nas`
        2.modify `/etc/auto.nas`:
        `data -intr,nfsv3 10.113.0.254:/net/data`
        `home -intr,nfsv3 10.113.0.254:/net/home`~~
        - direct map (use this)
        1.modify `/etc/auto_master`:
        `/-        /etc/auto.nas` 把沒註解掉的那行改成這個
        2.modify `/etc/auto.nas`:
         `/net/data -intr,nfsv3,nosuid,ro 10.113.0.254:/net/data`
        `/net/home -intr,nfsv3,nosuid 10.113.0.254:/net/home`
    - Then autofs can be started by running:
    ```
    service automount start
    service automountd start
    service autounmountd start
    ```
    - check if the files are mounted
## NFS Server
[NFS Server 端設定](https://dywang.csie.cyut.edu.tw/dywang/rhcsaNote/node61.html)


  發現無法mkdir資料夾，因為autofs不能用indirect map，要直接掛載到根目錄，用direct map

- Normal user access /net/share as UID=user, GID=users.(不用做)
**For NFS Server, please ignore "Normal user access /net/share as UID=user, GID=users" on HW5 Page 5.**
- /net/admin is read-only.(不用做)
**Three folders with same permission.**

所以modify /etc/exports
```
不確定唷
V4: /net -sec=sys
/net/alpha /net/share /net/admin -maproot=nobody
```
>是這樣設定嗎？？

| 參數        | 意義      |
| --------   | -------- |
| -ro        | 表示 read only，唯讀。  |
| -maproot=user|如果 client 以 root 存取，則將它的權限對映成本機 user 的權限。|
| -mapall=user	|將所有 client 的存取連線對映到 user，也就是說所有人的身份都轉成 user。|
| -alldirs	|可以讓使用者將該分享資料夾的任一目錄做為 mount point。也就是說當我們分享的是 /usr 時，client也可以將 /usr/include 當成掛入點來 mount。但前提是 /usr 必須是一個獨立的 filesystem，也就是說 /usr必須是獨立分割成一個 slice。|
| -network IP -mask MASK	| 指定允許連線的網域。
改完記得重啟動mountd
modify /etc/rc.conf `mountd_enable="YES"`
`sudo service mountd reload`

最後用 `showmount -e` 測 應該會看到那三個folder在export lists中

## firewall
[firewall ref](https://www.freebsd.org/doc/zh_TW/books/handbook/firewalls-ipfw.html)
- To configure the system to enable IPFW at boot time
`sudo sysrc firewall_enable="YES"`
- To use one of the default firewall types provided by FreeBSD, open: passes all traffic.
`sudo sysrc firewall_type="open"`
- After saving the needed edits, start the firewall.
`sudo service ipfw start`

```
sudo ipfw table BadHost create
sudo ipfw table BadGuy create
sudo ipfw add 1999 deny tcp from "table(BadGuy)" to any 21
sudo ipfw add 1999 deny tcp from "table(BadGuy)" to any 22
sudo ipfw add 2000 reject icmp from "table(BadGuy)" to any
sudo ipfw add 2000 reset tcp from "table(BadGuy)" to any
sudo ipfw add 3000 deny ip from "table(BadHost)" to any
sudo ipfw add 4000 deny icmp from not 10.113.0.254 to any
```
from其他人：
bad guy 是不是可以連ftp跟ssh以外的r 上面這個寫法會不會把這個擋掉..?
目前在下的寫法 (完全照spec一行一行刻)
```
ipfw add 2000 deny all from "table(BadHost)" to any in
ipfw add 2010 allow tcp from 10.113.0.0/16 to any 80 in
ipfw add 2011 allow tcp from 10.113.0.0/16 to any 443 in
ipfw add 2020 allow icmp from 10.113.0.254 to any in
ipfw add 2025 deny icmp from any to any in
ipfw add 2030 reset tcp from "table(BadGuy)" to any 21 in
ipfw add 2031 reset tcp from "table(BadGuy)" to any 22 in
```

[ipfw rules的語法](https://sites.google.com/site/altohornunix/12-wang-lu-fu-wu/12-4-fang-huo-qiang-ipfw/ipfwzhilingdeyufayucanshu)
- [action]表示這條規則要做的事
    - deny：
    拒絕通過的規則。
    - reject：
    拒絕通過的規則，符合規則的封包將被丟棄，並傳回一個host unreachable的ICMP。
- src, dist
    - src是封包來源，dist是封包目的地。可用關鍵字有any, me,或是以 <address/mask>[ports]的方式明確指定位址及埠號。
**any 表示符合這規則的所有ip位址**。
    - IP後可加上埠號：23 or 23-80 or 23,21,80，或在/etc/services中所定義的名稱，如ftp，在services中定義是21，因此寫**ftp則代表port 21, ssh代表port 22**

查看所有rule
`sudo ipfw list` or `sudo ipfw show`
查看table
`sudo ipfw table all list`
- check if the setting is correct
`sudo ipfw table BadGuy add 10.113.xx.xx`
    加完後這個人應該就登不進去了
## blacklist

```
sysrc blacklistd_enable=yes
service blacklistd start
sudo sysrc sshd_flags="-o UseBlacklist=yes"
sudo service sshd restart
```
因為 in `/usr/libexec/blacklistd-helper`
```
pf=
if [ -f "/etc/ipfw-blacklist.rc" ]; then
	pf="ipfw"
	. /etc/ipfw-blacklist.rc
	ipfw_offset=${ipfw_offset:-2000}
fi
```
要有/etc/ipfw-blacklist.rc這個file 他才會知道是ipfw 所以
`touch /etc/ipfw-blacklist.rc`就好

modify `/etc/blacklistd.conf`
>是remote ssh那邊(最後一行) 這樣嗎？
![](https://i.imgur.com/FfLHDaL.png)

改完重啟 `service blacklistd start`

check unban 
`sudo blacklistctl dump -a`
check ban 
`sudo blacklistctl dump -b`
or 加r可以看到remain time
`sudo blacklistctl dump -ar`

- Also apply the rules to FTP. (+5%)
>是這樣嗎？
在/etc/blacklistd.conf
![](https://i.imgur.com/ETLdr5Q.png)

- Personal webpage for NIS user. (+5%)
/usr/local/etc/nginx.conf 加入三個user的
```
location /people/~nisuser1 {
    alias /net/home/nisuser1/public_html;
    index index.html;
}   
```
