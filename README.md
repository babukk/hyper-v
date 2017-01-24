
Компиляция и установка winexe
-----------------------------
```
$ wget http://www.openvas.org/download/wmi/wmi-1.3.14.tar.bz2
$ bzip2 -cd wmi-1.3.14.tar.bz2 | tar xf -
$ cd wmi-1.3.14/Samba/source
$ ./autogen.sh
$ ./configure --without-readline --enable-debug
$ vi Makefile
```
Добавить -ffreestanding к CPP=gcc -E
т.е. должно быть так:
```
CPP=gcc -E -ffreestanding
```
```
$ make proto bin/wmic bin/winexe libraries
```

Скопировать из wmi-1.3.14/Samba/source/bin:
winexe (и wmic) в /usr/local/bin

На стороне Windows-сервера
--------------------------

Выполнить в powershell:
```
Set-ExecutionPolicy -Scope CurrentUser” an enter “remotesigned
```

Пример вызова:
```
use HyperV;
use Data::Dumper;

my $hyperv = new HyperV({
    'host' => '10.49.170.237',
    'username' => 'admin',
    'password' => 'password',
    'timeout' => 30,
});

my $vm_summary = $hyperv->GetVMSummary( 'computer_1' );
print Dumper($vm_summary);

my $vhds = $hyperv->GetVHD( 'computer_1' );
print Dumper($vhds);
```
