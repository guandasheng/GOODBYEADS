#!/bin/sh
LC_ALL='C'

rm *.txt

wait
echo '创建临时文件夹'
mkdir -p ./tmp/

#添加补充规则
cp ./data/rules/adblock.txt ./tmp/rules01.txt
cp ./data/rules/whitelist.txt ./tmp/allow01.txt

cd tmp
#下载yhosts规则
curl https://raw.githubusercontent.com/VeleSila/yhosts/master/hosts | sed '/0.0.0.0 /!d; /#/d; s/0.0.0.0 /||/; s/$/\^/' > rules001.txt

#下载大圣净化规则
curl https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts > rules002.txt
sed -i '/视频/d;/奇艺/d;/微信/d;/localhost/d' rules002.txt
sed -i '/127.0.0.1 /!d; s/127\.0\.0\.1 /||/; s/$/\^/' rules002.txt

#下载乘风视频过滤规则
curl https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/mv.txt | awk '!/^$/{if($0 !~ /[#^|\/\*\]\[\!]/){print "||"$0"^"} else if($0 ~ /[#\$|@]/){print $0}}' | sort -u > rules003.txt


echo '下载规则'
rules=(
  "https://raw.githubusercontent.com/8680/GOODBYEADS/master/rules.txt" #adg基础过滤器
  "https://adrules.top/dns.txt" #adg移动设备过滤器
  "https://anti-ad.net/easylist.txt"  #adgURL过滤器
  "https://github.com/Potterli20/file/releases/download/github-hosts/Accelerate-Hosts.txt" #adg防跟踪
  "https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/AWAvenue-Ads-Rule.txt" #adg中文过滤器
  "https://raw.githubusercontent.com/lingeringsound/10007_auto/master/reward" #Tv规则
  "https://raw.githubusercontent.com/5whys-adblock/AdGuardHome-rules/main/rules/output_full.txt" #EasyPrivacy隐私保护规则
  "https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/adblockdns.txt" #去APP下载提示规则
  "https://raw.githubusercontent.com/hululu1068/AdGuard-Rule/main/rule/adgh.txt" #d3ward规则
 )

allow=(
  "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/ChineseFilter/sections/allowlist.txt"
  "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/GermanFilter/sections/allowlist.txt"
  "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/TurkishFilter/sections/allowlist.txt"
  "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/SpywareFilter/sections/allowlist.txt"
)

for i in "${!rules[@]}" "${!allow[@]}"
do
  curl -m 60 --retry-delay 2 --retry 5 --parallel --parallel-immediate -k -L -C - -o "rules${i}.txt" --connect-timeout 60 -s "${rules[$i]}" |iconv -t utf-8 &
  curl -m 60 --retry-delay 2 --retry 5 --parallel --parallel-immediate -k -L -C - -o "allow${i}.txt" --connect-timeout 60 -s "${allow[$i]}" |iconv -t utf-8 &
done
wait
echo '规则下载完成'

# 添加空格
file="$(ls|sort -u)"
for i in $file; do
  echo -e '\n' >> $i &
done
wait

                                                        
echo 开始合并

cat *.txt > tmp-rule.txt & #允许清单处理
wait

echo 规则合并完成

#移动规则到Pre目录
cd ../
mkdir -p ./pre/
cp ./tmp/tmp-*.txt ./pre
cd ./pre

# Python 处理重复规则
python .././data/python/rule.py

# Start Add title and date
diffFile="$(ls|sort -u)"
for i in $diffFile; do
 n=`cat $i | wc -l` 
 echo "! Version: $(TZ=UTC-8 date +'%Y-%m-%d %H:%M:%S')（北京时间） " >> tpdate.txt 
 new=$(echo "$i" |sed 's/tmp-//g') 
 echo "! Total count: $n" > $i-tpdate.txt 
 cat ./tpdate.txt ./$i-tpdate.txt ./$i > ./$new 
 rm $i *tpdate.txt 
done

echo '更新统计数据'

cd ../

diffFile="$(ls pre |sort -u)"
for i in $diffFile; do
 titleName=$(echo "$i" |sed 's#.txt#-title.txt#') 
 cat ./data/title/$titleName ./pre/$i | awk '!a[$0]++'> ./$i 
 sed -i '/^$/d' $i 

done
wait
echo '更新成功'
rm -rf pre

exit
