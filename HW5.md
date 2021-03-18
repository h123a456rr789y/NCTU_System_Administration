# SA hw5 NIS&NFS

[大神a筆記](https://yuuki1532.wordpress.com/2020/01/05/sa-hw5-nisnfs/)
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
    - vipw 修改 /etc/master.passwd 將~~非系統本身的使用者移除~~，並在檔案最後加入下列一行：`+:::::::::`
    - vigr編輯 /etc/group，將~~非系統本身的使用者移除~~，並加入這一行：
    `+:*::`
- Set home directory of NIS user to be '/net/home/<username>' when they login 
```
sudo pw usermod nisuser1 -m /net/home
```
- 


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
- How to mount directories from NFS server
    - 執行 mount_nfs 指令時加上參數 -s 如此一來當 NFS Client 掛載 (mount) 失敗幾次之後便不再嘗試去 mount
    - 執行 mount_nfs 指令時加上參數 -i 為允許使用 Ctrl+C 來中斷掛載 (mount)
```
mount_nfs -s -i filecenter:/usr/home  /mnt/home 
```

- Auto Mounting
    - AMD(automounter daemon)
        - For more details plz look up the Ref link
    - Autofs
        - modify`/etc/rc.conf`:
        `autofs_enable=”YES”`
        - modify `/etc/auto_master`:
        ~~`/net        /etc/auto.nas`~~
        `/-        /etc/auto.nas`
        - modify `/etc/auto.nas`:
        ~~`data -intr,nfsv3 10.113.0.254:/net/data`
        `home -intr,nfsv3 10.113.0.254:/net/home`~~
        `/net/data -intr,nfsv3,nosuid,ro 10.113.0.254:/net/data`
        `/net/home -intr,nfsv3,nosuid 10.113.0.254:/net/home`
    

## NFS Server
[NFS Server 端設定](https://dywang.csie.cyut.edu.tw/dywang/rhcsaNote/node61.html)

- Exports
  - /net/alpha
  - /net/share
  - /net/admin
  發現無法mkdir資料夾，因為autofs不能用indirect map，要直接掛載到根目錄，用direct map
- When someone mount your storage as ‘root’, they only have permissions same as nobody.
- Normal user access /net/alpha as their own UID and GID.

- Normal user access /net/share as UID=user, GID=users.(應該不用做)
**For NFS Server, please ignore "Normal user access /net/share as UID=user, GID=users" on HW5 Page 5.**

- /net/admin is read-only.
- NFSv4 with nfsuserd for mapping UID and username.
- /etc/exports must be NFSv4 format.



<!-- `sudo service nfsd start`
`sudo service rpcbind start` -->

**這樣好像不是NFSv4 format，上面這樣打的話showmount會只有alpha**

![](https://i.imgur.com/eZp959y.png)

```
#這個是我的結果，不過不知道怎麼看有沒有符合spec
% showmount -e
Exports list on localhost:
/net/share                         Everyone
/net/alpha                         Everyone
/net/admin                         Everyone


% cat /etc/exports
V4: / -sec=sys
/net/alpha /net/share /net/admin -maproot=nobody -network 10.113.0.0/16
```

>是不是不用-ro啊？因為有人問助教這題 回答為 是![](https://i.imgur.com/rxoFovR.png)
>如果是這樣的話那應該就是我上面做得這樣了(?)
>只是不知道這個怎麼測NFSv4 with nfsuserd for mapping UID and username


[ NFS server](http://mail.lsps.tp.edu.tw/~gsyan/freebsd2001/nfs.html)


## firewall
```
sudo sysrc firewall_enable="YES"
sudo sysrc firewall_type="open"
sudo service ipfw start
```
(https://www.freebsd.org/doc/zh_TW/books/handbook/firewalls-ipfw.html)

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
---
bad guy 是不是可以連ftp跟ssh以外的r 上面這個寫法會不會把這個擋掉..?
目前在下的寫法 (完全照spec一行一行刻)
```
ipfw add 2000 deny ip from "table(BadHost)" to any in
ipfw add 2010 allow tcp from 10.113.0.0/16 to any 80 in
ipfw add 2011 allow tcp from 10.113.0.0/16 to any 443 in
ipfw add 2020 allow icmp from 10.113.0.254 to any in
ipfw add 2025 deny icmp from any to any in
ipfw add 2030 reset tcp from "table(BadGuy)" to any 21 in
ipfw add 2031 reset tcp from "table(BadGuy)" to any 22 in
```


## blacklist

```
sysrc blacklistd_enable=yes
service blacklistd start
sudo sysrc sshd_flags="-o UseBlacklist=yes"
sudo service sshd restart
```
還需再
- vim /etc/rc.conf加上
    - pf_enable="YES"
    - pf_rule="/path/to/pf.conf"
- vim /path/to/pf.conf
    - anchor "blacklistd/*" in on 網卡名稱
- vim /etc/blacklistd.conf
    ssh stream * * * 5 24h
    註解* * * * * 3 60


