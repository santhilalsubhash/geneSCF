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

@myout=split("/",$ARGV[1]);
open(RESULT,">@ARGV[2]/@{myout[$#myout]}_${ARGV[3]}_${ARGV[6]}_functional_classification.tsv");


$genescf_note="Note:Only KEGG supports multiple organisms (org_codes_help/KEGG_organism_codes.txt). If you choose GeneOntology please specify organism as 'goa_human' and for REACTOME, NCG as 'Hs'. Currently GeneOntology/REACTOME/NCG in GeneSCF only supports Human.";

#### KEGG DB ####

if($ARGV[0] eq "gid" && $ARGV[3] eq "KEGG")
{
$mytype="Entrez GeneID";

$kup=`find $ARGV[5]/class/lib/db/${ARGV[6]}/kegg_database.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$kup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $kup\n";

print "Example input types\n---------------\ngid |\tsym\n";
$gene_type=`curl -s http://rest.kegg.jp/list/${ARGV[6]} | grep -v "uncharacterized"| head -n10 | sed 's/^${ARGV[6]}\://' | sed 's/\;/\t/' | cut -d\$"\t" -f1,2`;
print $gene_type;

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}/kegg_database.txt") or die "Error opening in database file";

}
if($ARGV[0] eq "sym" && $ARGV[3] eq "KEGG")
{
$mytype="Gene Symbol";

$kup=`find $ARGV[5]/class/lib/db/${ARGV[6]}/kegg_database.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$kup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $kup\n";

print "Example input types\n---------------\ngid |\tsym\n";
$gene_type=`curl -s http://rest.kegg.jp/list/${ARGV[6]} | grep -v "uncharacterized"| head -n10 | sed 's/^${ARGV[6]}\://' | sed 's/\;/\t/' | cut -d\$"\t" -f1,2`;
print $gene_type;

print "=> Retreving gene list for ${ARGV[6]} from $ARGV[3]\n";
$cmd=`curl -s -S http://rest.kegg.jp/list/${ARGV[6]} | sed "s/${ARGV[6]}\://" > $ARGV[5]/mapping/DB/gene_list.txt;`;
print "=> Mapping user list\n";
$cmd=`perl $ARGV[5]/class/scripts/mappingIDS.pl $ARGV[5]/mapping/DB/gene_list.txt $ARGV[1] $ARGV[5] | awk '!x[\$0]++' > $ARGV[5]/mapping/user_mapped.list`;
$ulist=`wc -l $ARGV[1] | cut -d' ' -f1`;

$cmd=`cat $ARGV[5]/mapping/user_mapped.list | cut -f1 | awk '!x[\$0]++' > $ARGV[5]/mapping/@{myout[$#myout]}_input_list.txt`;
$mlist=`wc -l $ARGV[5]/mapping/@{myout[$#myout]}_input_list.txt | cut -d' ' -f1`;

$mlist=~ tr/\n//d;

$ulist=~ tr/\n//d;

$plist=($mlist/$ulist)*100;

print "Note: There were " . $mlist . " genes mapped from " . $ulist . " user provided unique genes ($plist %)\n";
$ginput="$ARGV[5]/mapping/@{myout[$#myout]}_input_list.txt";
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}/kegg_database.txt") or die "Error opening in database file";
}




#### GeneOntology DB ####

if($ARGV[0] eq "gid" && $ARGV[3] eq "GO_BP" && ${ARGV[6]} eq "goa_human")
{
$mytype="Entrez GeneID";

$goup=`find $ARGV[5]/class/lib/db/goa_human/GO_*.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$goup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $goup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}/GO_BP_gid.txt") or die "Error opening in database file";

}
if($ARGV[0] eq "sym" && $ARGV[3] eq "GO_BP" && ${ARGV[6]} eq "goa_human")
{
$mytype="Gene Symbol";

$goup=`find $ARGV[5]/class/lib/db/goa_human/GO_*.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$goup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $goup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}/GO_BP_sym.txt") or die "Error opening in database file";
}


if($ARGV[0] eq "gid" && $ARGV[3] eq "GO_CC" && ${ARGV[6]} eq "goa_human")
{
$mytype="Entrez GeneID";

$goup=`find $ARGV[5]/class/lib/db/goa_human/GO_*.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$goup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $goup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}/GO_CC_gid.txt") or die "Error opening in database file";

}
if($ARGV[0] eq "sym" && $ARGV[3] eq "GO_CC" && ${ARGV[6]} eq "goa_human")
{
$mytype="Gene Symbol";

$goup=`find $ARGV[5]/class/lib/db/goa_human/GO_*.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$goup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $goup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}/GO_CC_sym.txt") or die "Error opening in database file";
}


if($ARGV[0] eq "gid" && $ARGV[3] eq "GO_MF" && ${ARGV[6]} eq "goa_human")
{
$mytype="Entrez GeneID";

$goup=`find $ARGV[5]/class/lib/db/goa_human/GO_*.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$goup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $goup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}/GO_MF_gid.txt") or die "Error opening in database file";

}
if($ARGV[0] eq "sym" && $ARGV[3] eq "GO_MF" && ${ARGV[6]} eq "goa_human")
{
$mytype="Gene Symbol";

$goup=`find $ARGV[5]/class/lib/db/goa_human/GO_*.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$goup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $goup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}/GO_MF_sym.txt") or die "Error opening in database file";
}


if($ARGV[0] eq "gid" && $ARGV[3] eq "GO_all" && ${ARGV[6]} eq "goa_human")
{
$mytype="Entrez GeneID";

$goup=`find $ARGV[5]/class/lib/db/goa_human/GO_*.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$goup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $goup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}/GO_all_gid.txt") or die "Error opening in database file";

}
if($ARGV[0] eq "sym" && $ARGV[3] eq "GO_all" && ${ARGV[6]} eq "goa_human")
{
$mytype="Gene Symbol";

$goup=`find $ARGV[5]/class/lib/db/goa_human/GO_*.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$goup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $goup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}/GO_all_sym.txt") or die "Error opening in database file";
}



#### REACTOME DB ####


if($ARGV[0] eq "gid" && $ARGV[3] eq "REACTOME" && ${ARGV[6]} eq "Hs")
{
$mytype="Entrez GeneID";

$rup=`find $ARGV[5]/class/lib/db/${ARGV[6]}_$ARGV[3]/ReactomePathways_updated150605_RplcdIDs.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$rup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $rup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}_$ARGV[3]/ReactomePathways_updated150605_RplcdIDs.txt") or die "Error opening in database file";

}
if($ARGV[0] eq "sym" && $ARGV[3] eq "REACTOME" && ${ARGV[6]} eq "Hs")
{
$mytype="Gene Symbol";

$rup=`find $ARGV[5]/class/lib/db/${ARGV[6]}_$ARGV[3]/ReactomePathways_updated150605_geneSym.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$rup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $rup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}_$ARGV[3]/ReactomePathways_updated150605_geneSym.txt") or die "Error opening in database file";

}

#### NCG4.0 DB ####


if($ARGV[0] eq "gid" && $ARGV[3] eq "NCG" && ${ARGV[6]} eq "Hs")
{
$mytype="Entrez GeneID";

$nup=`find $ARGV[5]/class/lib/db/${ARGV[6]}_$ARGV[3]/NCG4.0_annotation_Updated150605_RplcdIDs.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$nup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $nup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}_$ARGV[3]/NCG4.0_annotation_Updated150605_RplcdIDs.txt") or die "Error opening in database file";

}
if($ARGV[0] eq "sym" && $ARGV[3] eq "NCG" && ${ARGV[6]} eq "Hs")
{
$mytype="Gene Symbol";

$nup=`find $ARGV[5]/class/lib/db/${ARGV[6]}_$ARGV[3]/NCG4.0_annotation_Updated150605_geneSym.txt -maxdepth 0 -printf "%TY-%Tm-%Td %TH:%TM\n" | head -n1`;
$nup=~ tr/\n//d;

print "$genescf_note";
print "\n$ARGV[3] last updated $nup\n";

$ginput=$ARGV[1];
open(IN1,"$ARGV[5]/class/lib/db/${ARGV[6]}_$ARGV[3]/NCG4.0_annotation_Updated150605_geneSym.txt") or die "Error opening in database file";

}

###### DB end #######



open(IN2,$ginput) or print "\n***\nError opening input file: $ARGV[1]\n***\n\n";


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
$N=$ARGV[4];




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

open(TEMP,">$ARGV[5]/mapping/@{myout[$#myout]}_${ARGV[3]}_${ARGV[6]}_functional_classification_temp.tsv");
open(IN3,"@ARGV[2]/@{myout[$#myout]}_${ARGV[3]}_${ARGV[6]}_functional_classification.tsv");

while(<IN3>){
	chomp;
	@temp1=split("\n",$_);
	foreach $temp1(@temp1)
	{
		@dat = split("\t",$temp1);
		@pros= split("~",$dat[1]);
		print TEMP "$pros[0]\t$pros[1]\t$dat[2]\t$dat[4]\t$dat[5]\n";
		
	}
}

close(TEMP);

$cmd=(`nohup Rscript $ARGV[5]/class/scripts/plot.R $ARGV[5]/mapping/@{myout[$#myout]}_${ARGV[3]}_${ARGV[6]}_functional_classification_temp.tsv @ARGV[2] @{myout[$#myout]}_${ARGV[3]}_${ARGV[6]} &`);
$cmd=(`rm $ARGV[5]/mapping/@{myout[$#myout]}_${ARGV[3]}_${ARGV[6]}_functional_classification_temp.tsv $ARGV[5]/mapping/DB/gene_list.txt`);

if(${ARGV[6]} eq "Hs" || ${ARGV[6]} eq "goa_human" || ${ARGV[6]} eq "hsa")
{
${ARGV[6]} = "Human"
}
print"=================\nRun successful. Check your output directory $ARGV[2] \n=================\n\nParameters used:\n\nOrganism:\t\t${ARGV[6]}\nbackground genes:\t$ARGV[4]\nIdentitiy:\t\t$mytype\nDatabase used:\t\t$ARGV[3]\nOutput file:\t\t@ARGV[2]@{myout[$#myout]}_${ARGV[3]}_functional_classification.tsv\n\t\tWARNING: Your output is not sorted with P-val/FDR.\n\n\n---------------------\n\nAuthor: Santhilal Subhash\nsanthilal.subhash\@gu.se\n"


