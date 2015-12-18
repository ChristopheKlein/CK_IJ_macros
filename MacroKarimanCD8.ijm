macro "MacroKarimanCD8 [1]"{

//*******************************************
NUCLEI_DIAM=8;
MASK_SMOOTH_RADIUS=8;
//MASK_THRESHOLD_METHOD="Triangle";
MASK_THRESHOLD_METHOD="Otsu";
ENLARGE=5;
MIN_CIRCULARITY=0.5;
MIN_AREA=100;
MAX_AREA_SPLIT=1000;
SEUIL_MEAN=185;
BATCH="exit and display";
//BATCH="false";//n'affiche pas les images intermediaires
//*******************************************

title=getTitle();
run("Select None");
run("Clear Results");

//setBatchMode(true);

//run("RGB Color");
//selectWindow(title+" (RGB)");
original=getImageID();

run("Colour Deconvolution", "vectors=[H&E DAB] hide");
selectWindow(title+"-(Colour_3)");
run("Duplicate...", "title=mask");
run("Duplicate...", "title=particules");

//DoG
d=NUCLEI_DIAM;
name=getTitle();
//original2=getImageID();
run("Duplicate...", "title=sig1");
run("Duplicate...", "title=sig2");

sigma1=1/(1+sqrt(2))*d;
sigma2=sqrt(2)*sigma1;

selectImage("sig1");
run("Gaussian Blur...", "sigma="+sigma1);
selectImage("sig2");
run("Gaussian Blur...", "sigma="+sigma2);

imageCalculator("Subtract create 32-bit", "sig1","sig2");
run("Grays");
rename(name + "DoG");
DoG=getImageID();

selectWindow("sig1");
close();
selectWindow("sig2");
close();
//end DoG

//voronoi
selectImage(DoG);
run("Enhance Contrast", "saturated=0.35");
run("Find Maxima...", "noise=1 output=[Maxima Within Tolerance]");
run("Duplicate...", "title=voronoi");
run("Voronoi");
setThreshold(0, 0);
run("Convert to Mask");

//particules and voronoi
selectImage("particulesDoG Maxima");
run("Options...", "iterations="+NUCLEI_DIAM+" count=1 black pad do=Dilate");
imageCalculator("AND create 32-bit", "particulesDoG Maxima","voronoi");
rename("particulesDoG Maxima Voronoi");
selectImage("particulesDoG Maxima Voronoi");
run("Make Binary");
run("Invert");
run("Options...", "iterations=3 count=3 black pad do=Open");
run("Watershed");

//Selection sur le mask
selectImage("mask");
run("Mean...", "radius="+MASK_SMOOTH_RADIUS);
//setAutoThreshold("Yen");
setAutoThreshold(MASK_THRESHOLD_METHOD);
run("Create Selection");

//Nettoyage particules exclure hors mask et enlever circularité<0.7 taille <100
selectImage("particulesDoG Maxima Voronoi");
run("Duplicate...", "title=particulesDoG_Maxima_Voronoi_filtrees");
run("Restore Selection");
run("Enlarge...", "enlarge="+ENLARGE);
//suprimer les particules en contact avec la selection
run("Analyze Particles...", "size="+MIN_AREA+"-5000 circularity="+MIN_CIRCULARITY+"-1.00 show=Masks exclude in_situ");
run("Select None");
run("Fill Holes");

//Creation mask
selectImage("mask");
run("Make Binary");
run("Fill Holes");
run("Watershed");
run("Options...", "iterations=3 count=3 black pad do=Open");
run("Duplicate...", "title=mask_filtre");
//Suprimer du mask les particules trop grosses pour les remplacer ensuite par particules max local
run("Analyze Particles...", "size="+MIN_AREA+"-"+MAX_AREA_SPLIT+" circularity="+MIN_CIRCULARITY+"-1.00 show=Masks in_situ");

//combiner mask et particules
imageCalculator("OR create 32-bit", "particulesDoG_Maxima_Voronoi_filtrees","mask_filtre");
run("Options...", "iterations=3 count=3 black pad do=Open");
run("Make Binary");
run("Watershed");
rename("particulesDoG_Maxima_Voronoi_mask");

roiManager("reset");
run("Clear Results");
run("Set Measurements...", "area mean standard modal min centroid integrated median limit redirect=None decimal=1");
//run("Analyze Particles...", "size="+MIN_AREA+"-Infinity show=Masks display exclude clear summarize add in_situ");
run("Analyze Particles...", "size="+MIN_AREA+"-Infinity show=Masks exclude add in_situ");

selectImage(original);
roiManager("measure");
roiManager("Show All");

setBatchMode(BATCH);

/*trier sur 
negatives :
rawID >60000
mean >195
*/

for(i=nResults-1;i>=0;i--){
	qq=getResult("Mean",i);
	//print(" " +i+" "+qq);
	if(qq>SEUIL_MEAN){
		roiManager("select",i);
		//print("delete "+i +" "+ getResult("Mean",i));
		roiManager("Delete");
	}
}

run("Clear Results");
selectImage(original);
roiManager("measure");
//run("Summarize");
roiManager("Show All");
print("image "+title+" : " +nResults+" cellules, mean intensity> "+SEUIL_MEAN);


//close images
if (BATCH=="exit and display"){

	selectImage("particules");
	close();
	selectImage(title+"-(Colour_2)");
	close();
	selectImage(title+"-(Colour_1)");
	close();
	
	waitForUser("Close images","click OK to exit");
	
	selectImage("mask");
	close();
	selectImage("mask_filtre");
	close();
	selectImage("particulesDoG Maxima Voronoi");
	close();
	selectImage("particulesDoG Maxima");
	close();
	selectImage("voronoi");
	close();
	selectImage("particulesDoG");
	close();
	selectImage(title+"-(Colour_3)");
	close();
	selectImage(title);
	//close();
	selectImage("particulesDoG_Maxima_Voronoi_mask");
	close();
	selectImage("particulesDoG_Maxima_Voronoi_filtrees");
	close();
	}
}