#!/bin/bash
organism=$1;
DIR=$2;
#GeneDB_Lmajor,GeneDB_Pfalciparum,GeneDB_Tbrucei,PAMGO_Atumefaciens,PAMGO_Ddadantii,PAMGO_Mgrisea,PAMGO_Oomycetes,aspgd,cgd,dictyBase,ecocyc,fb,goa_chicken,goa_cow,goa_dog,goa_human,goa_pdb,goa_pig,goa_ref_chicken,goa_ref_cow,goa_ref_dog,goa_ref_human,goa_ref_pig,goa_uniprot_noiea,goa_uniprot,gramene_oryza,jcvi,mgi,pombase,pseudocap,rgd,sgd,sgn,tair,wb,zfin,
#Depends on the database of the organism the taxonid should change in gene_info extraction cat $DIR/class/lib/db/gene_info | grep "^9606" | awk -F '\t' '{print $3"\t"$2;}' > $bpath/geneSymWithID.txt;
bpath="$DIR/class/lib/db/$organism";
mkdir -p $bpath
rm $bpath/go.obo;
#http://www.berkeleybop.org/ontologies/obo/obo-all.tar.gz
wget -P  $bpath/ http://purl.obolibrary.org/obo/go.obo;
wget -P  $bpath/ http://geneontology.org/gene-associations/gene_association.${organism}.gz;

#gene_association.goa_human.gz renamed gene_association.goa_human140122

gzip -d -f $bpath/gene_association.${organism}.gz;

cat $bpath/go.obo | grep "^id\:" | sed 's/id: //' >  $bpath/GO_id.txt;
cat $bpath/go.obo | grep "^name\:" | sed 's/name: //' >  $bpath/GO_desc.txt;
cat $bpath/go.obo | grep "^namespace\:" | sed 's/namespace: //' >  $bpath/GO_process.txt;
##paste $bpath/GO_id.txt $bpath/GO_desc.txt >  $bpath/GOWithDesc.txt;
#cat $bpath/GOWithDesc.tmp | grep "^GO:" > $bpath/GOWithDesc.txt;
##paste $bpath/GOWithDesc.txt $bpath/GO_process.txt | awk -F '\t' '{print $1"\t"$3"\t"$2;}' >  $bpath/GOWithDescProcess.txt;
#cat $bpath/GOWithDescProcess.tmp | grep "^GO:" > $bpath/GOWithDescProcess.txt ;

paste $bpath/GO_id.txt $bpath/GO_desc.txt $bpath/GO_process.txt | awk -F '\t' '{print $1"\t"$3"\t"$2;}' | grep "^GO:" > $bpath/GOWithDescProcess.txt;

org_taxid=`cat $bpath/gene_association.${organism} | grep -v "\!" | cut -f13 | head -n1 | sed 's/taxon\://'`;
cat $bpath/gene_association.${organism} | grep -v "\!" | awk 'BEGIN{FS="\t"}{if($12~"protein" || $12~"gene") print $3"\t"$5"\t"$9;}' | awk '!x[$0]++'>  $bpath/all_go.tmp;
cat $bpath/all_go.tmp | awk '{print $2"\t"$1}' >  $bpath/temp1.txt;

awk 'BEGIN{FS="\t"}{ if( !seen[$1]++ ) order[++oidx] = $1; stuff[$1] = stuff[$1] $2 "," } END { for( i = 1; i <= oidx; i++ ) print order[i]"\t"stuff[order[i]] }'  $bpath/temp1.txt >  $bpath/gene_association.grouped.txt;

cat $bpath/gene_association.grouped.txt | cut -f1 > $bpath/temp2.txt;

perl $DIR/class/scripts/common.pl $bpath/GOWithDescProcess.txt  $bpath/temp2.txt $DIR > $bpath/gene_association.grouped.annotation;



sort -k1 $bpath/gene_association.grouped.annotation > $bpath/gene_association.grouped.annotation.tmp1
sort -k1 $bpath/gene_association.grouped.txt | grep "^GO:" > $bpath/gene_association.grouped.txt.tmp1

join -t $'\t' -j1 $bpath/gene_association.grouped.annotation.tmp1 $bpath/gene_association.grouped.txt.tmp1 | awk -F"\t" '{print $1"~"$3"\t"$2"\t"$4;}' > $bpath/gene_association.grouped.annotated.txt;






#cat gene_association.grouped.annotated.txt | awk -F'\t' -vOFS='\t' '{gsub(",","\t",$3);}{print ;}' > gene_association.grouped.annotated_formatted.txt;

cat $bpath/gene_association.grouped.annotated.txt | awk 'BEGIN{FS="\t"}{if($2~"molecular_function") print $1"\t"$3;}' >  $bpath/GO_MF_sym.txt;
cat $bpath/gene_association.grouped.annotated.txt | awk 'BEGIN{FS="\t"}{if($2~"cellular_component") print $1"\t"$3;}' >  $bpath/GO_CC_sym.txt;
cat $bpath/gene_association.grouped.annotated.txt | awk 'BEGIN{FS="\t"}{if($2~"biological_process") print $1"\t"$3;}' >  $bpath/GO_BP_sym.txt;
cat $bpath/gene_association.grouped.annotated.txt | awk 'BEGIN{FS="\t"}{print $1"\t"$3;}'>  $bpath/GO_all_sym.txt;


#WITH ID's

#$DIR/class/scripts/wget -P  $DIR/class/lib/db/ ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz;
#gzip -d  $DIR/class/lib/db/gene_info.gz;
#cat $DIR/class/lib/db/gene_info | grep -v "^#" | awk -F '\t' '{print $1"\t"$3"\t"$2;}' > $DIR/class/lib/db/gene_info_limit;
#rm $DIR/class/lib/db/gene_info;
############## Please change taxon for different organisms
#if [ $organism == "goa_human" ]; then
#$org_taxid = "9606"
#fi
#if [ $organism == "goa_dog" ]; then
#Canis lupus
#$org_taxid = "9615"
#fi
#if [ $organism == "goa_chicken" ]; then
#Gallus gallus
#$org_taxid = "9031"
#fi
#if [ $organism == "goa_cow" ]; then
#Bos taurus
#$org_taxid = "9913"
#fi
#if [ $organism == "goa_pig" ]; then
#Bos taurus
#$org_taxid = "9823"
#fi



gzip -d $DIR/class/lib/db/gene_info_limit.gz
cat $DIR/class/lib/db/gene_info_limit | grep -w "^$org_taxid" | awk -F '\t' '{print $2"\t"$3;}' > $bpath/geneSymWithID.txt;
gzip $DIR/class/lib/db/gene_info_limit;

awk 'BEGIN{FS="\t"}{ if( !seen[$1]++ ) order[++oidx] = $1; stuff[$1] = stuff[$1] $2 "," } END { for( i = 1; i <= oidx; i++ ) print order[i]"\t"stuff[order[i]] }' $bpath/geneSymWithID.txt | sed 's/,$//' > $bpath/geneSymWithID_DupGrpd.txt;

perl $DIR/class/scripts/replaceIDS.pl $bpath/GO_MF_sym.txt $bpath/geneSymWithID_DupGrpd.txt $DIR > $bpath/GO_MF_gid.txt
perl $DIR/class/scripts/replaceIDS.pl $bpath/GO_CC_sym.txt $bpath/geneSymWithID_DupGrpd.txt $DIR > $bpath/GO_CC_gid.txt
perl $DIR/class/scripts/replaceIDS.pl $bpath/GO_BP_sym.txt $bpath/geneSymWithID_DupGrpd.txt $DIR > $bpath/GO_BP_gid.txt
perl $DIR/class/scripts/replaceIDS.pl $bpath/GO_all_sym.txt $bpath/geneSymWithID_DupGrpd.txt $DIR > $bpath/GO_all_gid.txt


rm $bpath/all_go.tmp $bpath/gene_association.${organism}  $bpath/gene_association.grouped.annotated.txt  $bpath/gene_association.grouped.annotation  $bpath/gene_association.grouped.txt  $bpath/go.obo  $bpath/GO_desc.txt  $bpath/GO_id.txt  $bpath/GO_process.txt $bpath/GOWithDescProcess.txt $bpath/geneSymWithID.txt $bpath/geneSymWithID_DupGrpd.txt $bpath/gene_association.grouped.annotation.tmp1 $bpath/gene_association.grouped.txt.tmp1 $bpath/temp1.txt $bpath/temp2.txt

