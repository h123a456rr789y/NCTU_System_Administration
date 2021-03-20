###### tags: `SA`
# SA hw4
https://hackmd.io/0dIy9vLuSqydRT-dwSjQdA?fbclid=IwAR3gahi465-UHas5Nm_aFI20mVpqX2tq2oMCUfJxyRhM5FISrlTqSiHTwZw
## create Domain name

create Domain name on nctu.me
> 據某同學：如果bsd裝在VM裡，你要demo的電腦裝wireguard 下發的ip，然後domain指到bsd在wiregurad裡面的ip，但我還沒試QAQ
> 要測網頁可以先用 local resolve 頂一下 → 改 hosts

>> - 助教在第一次和第二次給的wireguard ip都可以用XDDD
>> - 所以本機也要裝wireguard，用的就是其中一組虛擬IP，VM接的是另一組
>> - 這樣本機就代表是走跟VM不同的路（他作業的public ip要求）
>> - 設定是開兩個adapter，一個NAT和一個host-only
>> - 要private ip的話代表本機要走VM那條，可以直接打本機對應到VM的那個IP

## sever on Nginx

(X)http://blog.snowtec.org/2013/05/nginx-php-fpm-on-freebsd/
(o)https://www.cyberciti.biz/faq/freebsd-install-php-7-2-with-fpm-for-nginx/

## set up nginx.conf
https://blog.hellojcc.tw/2015/12/07/nginx-beginner-tutorial/

## Hide NGINX/Apache version in header (5%)
https://www.tecmint.com/hide-nginx-server-version-in-linux/
`server_tokens off;`

## HTTPS
### openssl (enable HTTPS) (5%)

https://www.digitalocean.com/community/tutorials/how-to-create-an-ssl-certificate-on-nginx-for-ubuntu-14-04?fbclid=IwAR2eTnR8v3VJUVDK3j8doGLe9uNApaw5lEvezgbm0yFnU7rWT51v0KlAu_U
https://blog.gtwang.org/linux/nginx-create-and-install-ssl-certificate-on-ubuntu-linux/

`$ sudo mkdir /etc/nginx/ssl`
`$ sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt`

(**supply -k option when testing with curl????這是什麼啊看不懂**)
> 如果要用 `curl` 來測試的話要加上 `-k`，insecure的連線中如果不加上`-k` 的話會出現SSL cetificate problem，不過對作業來說好像不是很重要
### Redirect to HTTPS automatically when attempting to connect to HTTP (5%)
```
server {
  listen 80 default_server;

  # 導向至 HTTPS (add this only !!)
  rewrite ^(.*) https://$host$1 permanent;
}
server {

  listen 443 ssl default_server;


  ssl_certificate /etc/nginx/ssl/nginx.crt;
  ssl_certificate_key /etc/nginx/ssl/nginx.key;

}
```
### Enable HSTS(5%)
https://note.qidong.name/2017/09/nginx-https-hsts/
`add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;`
其實我不知道要怎看他到底有沒有用HSTS(已解決)
> 右鍵 -> 檢查 -> network -> header，會看到一行跟這個很像的
> 耶感謝
### Enable HTTP2 on pages connected with HTTPS (5%)
```查看http version
$ curl -sI https://curl.haxx.se -o/dev/null -w '%{http_version}\n'
會回傳 2 才是http2，不然正常是1.1
```
> 是只要在443後面加上http2就好嗎？

https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-with-http-2-support-on-ubuntu-18-04

## Access Control
https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/

[How do I generate an .htpasswd file without having Apache tools installed?](https://www.nginx.com/resources/wiki/community/faq/)
[Create the Password File Using the OpenSSL Utilities(前半段)](https://www.digitalocean.com/community/tutorials/how-to-set-up-password-authentication-with-nginx-on-ubuntu-14-04)

## PHP/PHP-FPM
### setup PHP (3%)
https://www.cyberciti.biz/faq/freebsd-install-php-7-2-with-fpm-for-nginx/

### Hide PHP version information in header (2%)
https://www.tecmint.com/hide-php-version-http-header/
https://blog.xuite.net/soaring.liou/PHPTest/200646312-PHP+%E8%B3%87%E6%96%99%E5%A4%BE%E8%A3%A1%E6%B2%92%E6%9C%89+php.ini+%EF%BC%9F
```
$ php -i | grep "Loaded Configuration File"
如果是none，可以複製/usr/local/etc/php.ini-development 把它改成php.ini

$ sudo cp /usr/locol/etc/php.ini /usr/locol/etc/php.ini.orig
$ sudo vim /usr/locol/etc/php.ini
expose_php = off
```

要怎看他有hide information？（已解決）
> 右鍵 -> 檢查 -> network -> header
> 謝啦嘿嘿
## MySQL
### Install MySQL Server 
(x)[Install MySQL Server with phpMyAdmin on FreeBSD 11](https://www.howtoforge.com/tutorial/how-to-install-mysql-server-with-phpmyadmin-on-freebsd-11/)
(o)[Install Nginx, MySQL, PHP (FEMP) Stack on FreeBSD 12](https://kifarunix.com/install-nginx-mysql-php-femp-stack-on-freebsd-12/)
```
$ mysql -u root -p 
```
### Set the transaction isolation levels to READ-COMMITED (3%)
https://dev.mysql.com/doc/refman/8.0/en/set-transaction.html
```
查看
mysql> SELECT @@GLOBAL.tx_isolation;
ps.如果是裝mysql8(新版本), 要打.transaction_isolation
```
設 isolation level
```
記得是兩個T喔！！
SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;
```
### Bonus: Explain what this and other isolation levels mean (+5%)
- 資料庫的交易(Transaction)功能，能確保多個 SQL 指令，全部執行成功，或全部不執行，不會因為一些意外狀況，而只執行一部份指令，造成資料異常。
- 交易功能4個特性 (ACID)
    - Atomicity (原子性、不可分割)：交易內的 SQL 指令，不管在任何情況，都只能是全部執行完成，或全部不執行。若是發生無法全部執行完成的狀況，則會回滾(rollback)到完全沒執行時的狀態。
    - Consistency (一致性)：交易完成後，必須維持資料的完整性。所有資料必須符合預設的驗證規則、外鍵限制...等。
    - Isolation (隔離性)：多個交易可以獨立、同時執行，不會互相干擾。這一點跟後面會提到的「隔離層級」有關。
    - Durability (持久性)：交易完成後，異動結果須完整的保留。
- 其中 Isolation 是為了防止多個 Transactions 同時執行導致資料不一致的情況，而 Isolation 中又有所謂的 Isolation Levels ，根據 SQL-92 的標準分為 4 種級別：
    - Repeatable Read
    - Read Committed
    - Read Uncommitted
    - Serializable
- 詳細解釋isolation levels
https://myapollo.com.tw/zh-tw/database-transaction-isolation-levels/
https://medium.com/getamis/database-transaction-isolation-a1e448a7736e
https://xyz.cinc.biz/2013/05/mysql-transaction.html
### Create a MySQL user named ‘nc’ and a database named ‘nextcloud’, which satisfies:
https://qiita.com/liubin/items/3722ab10a73154863bd4
https://www.opencli.com/mysql/mysql-add-new-users-databases-privileges
```
mysql> mysql -u root -p
mysql> CREATE USER 'newuser'@'localhost' IDENTIFIED BY 'user_password';
```
- 如果噴ERROR 1820 (HY000): You must reset your password using ALTER USER statement before executing this statement
需要重新设置密码。那我们就重新设置一下密码，命令如下：
mysql> set password = password('xxxxx');

- 再打一次
mysql> CREATE USER 'newuser'@'localhost' IDENTIFIED BY 'user_password';
- 會報錯
ERROR 1819 (HY000): Your password does not satisfy the current policy requirements
- 因此要**Change MySQL password policy**：
mysql> SHOW VARIABLES LIKE 'validate_password%';
mysql> SET GLOBAL validate_password_length=7;
- 建立database
```
mysql> CREATE DATABASE nextcloud;
```
- 然後給予新帳號 “newuser” 權限讀寫新資料庫 “nextcloud”:
```
mysql> GRANT ALL PRIVILEGES ON nextcloud.* TO 'newuser'@'localhost';
mysql> FLUSH PRIVILEGES;
mysql> quit
```
- 測試一下新帳號 “newuser” 是否可以使用新資料庫 “newdatabase”:
```
mysql -u newuser -p
mysql> use nextcloud
```


### ignore
mysql passwd=andrea0719
nextcloud root andrea/0719
https://linuxize.com/post/how-to-create-mysql-user-accounts-and-grant-privileges/

## Basic App Router
- app/
在 location /app
修改 fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
改成fastcgi_param SCRIPT_FILENAME $document_root/index.php;
- app/A+B
[explode用法](https://codertw.com/%E7%A8%8B%E5%BC%8F%E8%AA%9E%E8%A8%80/212226/)
在index.php看
_SERVER['REQUEST_URI'] #訪問此頁面所需的 URI。例如「/index.html」。
> 我是把網址抓下來分析判斷給結果
- app?name=string
[pass var to php script via browser](https://stackoverflow.com/questions/9612166/how-do-i-pass-parameters-into-a-php-script-through-a-webpage)

## websocket
> 有沒有人做了啊QQ大卡關

## nextcloud
可以用網頁裝 https://nextcloud.com/install/#instructions-server
```
sudo pkg install php72-gd
sudo pkg install php72-openssl
sudo pkg install php72-zlib
sudo pkg install php72-curl
sudo pkg install php72-zip
sudo pkg install php72-mbstring
sudo pkg delete php72-pdo_sqlite
sudo pkg install php72-pdo_mysql
```

####  Error SQLSTATE[HY000] [2054] The server requested authentication method unknown to the client
https://www.itread01.com/content/1532371255.html

### When accessing https://{your-domain}/sites/~{username}/ , it should show whatever {username} put in his public_html, with index index.html

上傳的檔案路徑 /web_page_dir/nextcloud/data/user_name/files/public_html
personal page -> 用轉目錄的方式導到網頁的地方 -> http://phorum.study-area.org/index.php?topic=21235.0 
> 這個是把那個資料夾的所有檔案顯示出來？還是把它裡面的檔案當成一個 index.html 顯示？
> 第二個吧～

https://docs.nextcloud.com/server/13.0.0/admin_manual/installation/nginx.html
