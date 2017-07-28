original = getImageID();
run("8-bit");
original_title=getTitle();

for (i=3;i<20;i=i+2){
	selectImage(original);
	run("Duplicate...", "title=&i");
	run("Gray Morphology", "radius=&i type=circle operator=open");
	processed_title=getTitle();
	imageCalculator("Subtract create 32-bit", original_title,processed_title);
	rename("white_tophat_"+i);
	imageCalculator("Subtract create 32-bit", processed_title, original_title);
	rename("black_tophat"+i);
	selectImage(processed_title);
	run("Close");
}
