#!/usr/bin/perl

$/=undef;
use Cwd;
$pwd=cwd();
use lib "$ARGV[5]/class/lib";
use lib "$ARGV[5]/class//lib/Tie-IxHash-1.23";
use Tie::IxHash;
use Statistics::Multtest qw(bonferroni holm hommel hochberg BH BY qvalue);
use Statistics::Multtest qw(:all);
tie %kegg, 'Tie::IxHash';
use Text::NSP::Measures::2D::Fisher::right;
use Number::FormatEng qw(:all);
use Data::Dumper;

$GTYPE = $ARGV[0];
$INFILE = $ARGV[1];
$OUTPATH = $ARGV[2];
$database = $ARGV[3];
$background = $ARGV[4];
$DIR = $ARGV[5];
$organism = $ARGV[6];
$plot = $ARGV[7];



@myout=split("/",$INFILE);
open(RESULT,">$OUTPATH/@{myout[$#myout]}_${database}_${organism}_functional_classification.tsv");


$genescf_note="Note:Only KEGG and Geneontology supports multiple organisms (GeneSCF-xx/org_codes_help). If you choose REACTOME/NCG database please specify organism as 'Hs'. Currently REACTOME and NCG in GeneSCF only supports Human (Hs).";

#### KEGG DB ####



if($GTYPE eq "gid" && $database eq "KEGG")
{
$mytype="Entrez GeneID";

$kup=`find $DIR/class/lib/db/${organism}/kegg_database.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$kup=~ tr/\n//d;

print "$genescf_note";
print "\n$database last updated $kup\n";

print "Example input types\n---------------\ngid |\tsym\n";
$gene_type=`curl -s http://rest.kegg.jp/list/${organism} | grep -v "uncharacterized"| head -n10 | sed 's/^${organism}\://' | sed 's/\;/\t/' | cut -d\$"\t" -f1,2`;
print $gene_type;

$ginput=$INFILE;
open(IN1,"$DIR/class/lib/db/${organism}/kegg_database.txt") or die "Error opening in database file";

}
if($GTYPE eq "sym" && $database eq "KEGG")
{
$mytype="Gene Symbol";

$kup=`find $DIR/class/lib/db/${organism}/kegg_database.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$kup=~ tr/\n//d;

print "$genescf_note";
print "\n$database last updated $kup\n";

print "Example input types\n---------------\ngid |\tsym\n";
$gene_type=`curl -s http://rest.kegg.jp/list/${organism} | grep -v "uncharacterized"| head -n10 | sed 's/^${organism}\://' | sed 's/\;/\t/' | awk '{print \$1"\t"\$2;}'`;
print $gene_type;

print "=> Retreving gene list for ${organism} from $database\n";
$cmd=`curl -s -S http://rest.kegg.jp/list/${organism} | sed "s/${organism}\://" > $DIR/mapping/DB/gene_list.txt;`;
print "=> Mapping user list\n";
$cmd=`perl $DIR/class/scripts/mappingIDS.pl $DIR/mapping/DB/gene_list.txt $INFILE $DIR | awk '!x[\$0]++' > $DIR/mapping/user_mapped.list`;
$ulist=`wc -l $INFILE | cut -d' ' -f1`;

$cmd=`cat $DIR/mapping/user_mapped.list | cut -f1 | awk '!x[\$0]++' > $DIR/mapping/@{myout[$#myout]}_input_list.txt`;
$mlist=`wc -l $DIR/mapping/@{myout[$#myout]}_input_list.txt | cut -d' ' -f1`;

$mlist=~ tr/\n//d;

$ulist=~ tr/\n//d;

$plist=($mlist/$ulist)*100;

if($mlist>0)
{
print "Note: Since you used Gene Symbol as identifier, the accuracy will be less, for better results use Entrez UIDs.\n There were " . $mlist . " genes mapped from " . $ulist . " user provided unique genes ($plist %)\n";
$ginput="$DIR/mapping/@{myout[$#myout]}_input_list.txt";
open(IN1,"$DIR/class/lib/db/${organism}/kegg_database.txt") or die "Error opening in database file";
}
if($mlist<1)
{

print "Note: There were " . $mlist . " genes mapped from " . $ulist . " user provided unique genes ($plist %)\nPlease cross-check your gene identifier.";
exit;
}
}




#### GeneOntology, REACTOME, NCG DB ####


if($database eq "GO_BP" || $database eq "GO_CC" || $database eq "GO_MF" || $database eq "GO_all" || $database eq "REACTOME" || $database eq "NCG")
{
	if($GTYPE eq "gid")
	{
		$mytype="Entrez GeneID";
	}
	if($GTYPE eq "gid")
	{
		$mytype="Entrez GeneID";
	}
	if($GTYPE eq "sym")
	{
		$mytype="Gene Symbol";
	}

$goup=`find $DIR/class/lib/db/${organism}/${database}_${GTYPE}.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$goup=~ tr/\n//d;

print "$genescf_note";
print "\n$database last updated $goup\n";


$ginput=$INFILE;
open(IN1,"$DIR/class/lib/db/${organism}/${database}_${GTYPE}.txt") or die "Error opening in database file";


}



###### DB end #######



open(IN2,$ginput) or print "\n***\nError opening input file: $INFILE\n***\n\n";


print RESULT "Genes\tProcess~name\tnum_of_Genes\tgene_group\tpercentage%\tP-value\tEASE (http://david.abcc.ncifcrf.gov/content.jsp?file=functional_annotation.html#fisher) \tBenjamini and Hochberg (FDR)\t Hommel singlewise process\tBonferroni single-step process\tHommel singlewise process\tHochberg step-up process\tBenjamini and Yekutieli\n";

while(<IN1>){
	chomp;
	@temp1=split("\n",$_);
	foreach $temp1(@temp1)
	{
		@ar1 = split("\t",$temp1);
		$kegg{$ar1[0]} = ["$ar1[1]"];
	}
}



while(<IN2>){
	@temp2=split("\n",$_);
	foreach $temp2(@temp2)
	{
		@ar2 = split("\t",$temp2);
		$bp{$ar2[0]} = $ar2[0];
	}
}
$gene_list=@temp2;

@mykeys=();	
foreach my $keykg ( keys %kegg )
{
	
	@kgene=split(",",$kegg{$keykg}[0]);
	$kcount=1;
	$gcount=1;
	$gnum=0;
	@gset=();
	foreach $kgene(@kgene)
	{$knum=$kcount++;
				if(exists $bp{$kgene})
				{
					$gnum=$gcount++;
					$indgene=$bp{$kgene}.";";
					push(@gset,$indgene);
					##print RESULT $bp{$kgene}.";";
				}
				
					
	}


if($gnum>0)
{
$x=$gnum;
$n=$gene_list;
$M=$knum; ## total genes in process
$N=$background;




$fisher_value = calculateStatistic( n11=>$x,n1p=>$n,np1=>$x+$M,npp=>$N+$n);
$ease_value= calculateStatistic( n11=>$x-1,n1p=>$n,np1=>$x+$M,npp=>$N+$n);

push(@new,$fisher_value);

##print RESULT "\t$keykg\t$kegg{$keykg}[0]\t$gnum\t$knum\t$fisher_value\t$ease_value\n";
$percent=(($gnum/$knum)*100);
push(@finres,"@gset\t$keykg\t$gnum\t$knum\t$percent\t$fisher_value\t$ease_value\t");

}


}

$p=\@new;
$bhres = BH($p);
$holmres = holm($p);
$bfres=bonferroni($p);
$hommel=hommel($p);
$hochberg=hochberg($p);
$byres=BY($p);


for($i=0;$i<=$#finres;$i++)
{
print RESULT $finres[$i];
print RESULT @$bhres[$i]."\t".@$holmres[$i]."\t".@$bfres[$i]."\t".@$hommel[$i]."\t".@$hochberg[$i]."\t".@$byres[$i]."\n";

}




close(RESULT);
if($plot eq "yes")
{
open(TEMP,">$DIR/mapping/@{myout[$#myout]}_${database}_${organism}_functional_classification_temp.tsv");
open(IN3,"$OUTPATH/@{myout[$#myout]}_${database}_${organism}_functional_classification.tsv");

while(<IN3>){
	chomp;
	@temp1=split("\n",$_);
	foreach $temp1(@temp1)
	{
		@dat = split("\t",$temp1);
		
		
			print TEMP "$dat[1]\t$dat[4]\t$dat[5]\n";
		
		
	}
}

close(TEMP);


$cmd=(`nohup Rscript $DIR/class/scripts/bubble.R $DIR/mapping/@{myout[$#myout]}_${database}_${organism}_functional_classification_temp.tsv $OUTPATH @{myout[$#myout]}_${database}_${organism} $database &`);
$cmd=(`rm $DIR/mapping/@{myout[$#myout]}_${database}_${organism}_functional_classification_temp.tsv`);
}
if($plot eq "no")
{
print "No graphical output prefered";
}

if(${organism} eq "Hs" || ${organism} eq "goa_human" || ${organism} eq "hsa")
{
${organism} = "Human/Homo sapiens"
}
print"=================\nRun successful. Check your output directory $OUTPATH \n=================\n\nParameters used:\n\nOrganism:\t\t${organism}\nbackground genes:\t$background\nIdentitiy:\t\t$mytype\nDatabase used:\t\t$database\nOutput file:\t\t$OUTPATH@{myout[$#myout]}_${database}_functional_classification.tsv\n\t\tWARNING: Your output is not sorted with P-val/FDR.\n\n\n---------------------\n\nAuthor: Santhilal Subhash\nsanthilal.subhash\@gu.se\n"


