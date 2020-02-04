///////////////////////////////////////////////////////////////////////////////////////////////
//// Name: 	FFT de-stripper
//// Author:	Sébastien Tosi (IRB / Barcelona)
//// Version:	1.0
////
//// Usage:	Check help in dialog box
////
//// Note:	Only tested for Fiji liefeline June 2014
////	
///////////////////////////////////////////////////////////////////////////////////////////////

// Dialog box
html = "<html>"
     +"<h2>FFT de-stripper</h2>"
     +"<font size=+1>
     +"<br>This filter is meant to attenuate parallel, periodic stripes by FFT filtering."
     +"<br>It can be adjusted by moving 2 symmetric cut cones to mask out the region"
     +"<br>contaminated by the stripes. This region can be identified in the spectrum of the image"
     +"<br>as 2 peaks symmetrically positioned around the center (see image below)."
     +"<p><br><img src=\"https://raw.githubusercontent.com/SebastienTs/FFTdeStriper/master/FilterDim.png\" alt=\"FFT image\"><br><p/>" 
     +"<br><b>Angle (a):</b> Cones angle (degrees), tick <i>manually estimate angle</i> to estimate from image spectrum<br>"
     +"<br><b>Xoffset (d):</b> Cones distance to center (image width fraction): used to preserve useful spectrum, typ. [0.05-0.1]<br>"
     +"<br><b>Ywidth (W):</b> Cones width (image width fraction): the wider the stronger the filter, typ. [0.05-0.1]<br>"
     +"<br><b>Blur radius:</b> Notch filter blur radius (pix): used to avoid ringing, typ. [4-12]<br>"
     +"<br><b>Iterations:</b> Number of filter repetition times<br>"
Dialog.create("FFT de-stripper");
Dialog.addHelp(html);
Dialog.addNumber("Angle (a)", -13);
Dialog.addNumber("Xoffset fraction (d)", 0.05);
Dialog.addNumber("Ywidth  fraction (W)", 0.1);
Dialog.addNumber("Blur radius", 8);
Dialog.addNumber("Iterations", 2);
Dialog.addCheckbox("Manually estimate angle?", false);
Dialog.show();
Angle = Dialog.getNumber();
foffsX = Dialog.getNumber();
fwdthY = Dialog.getNumber();
RadBlur = Dialog.getNumber();
Iter = Dialog.getNumber();
EstimateAngle = Dialog.getCheckbox();

// Estimate FFT filter angle
ImageID = getImageID();
N = nSlices;
if(EstimateAngle==true)
{
	if(N>1)
	{
		waitForUser("Select a slice where stripes are clearly apparent");
		run("Duplicate...", "title=Slice");
		SliceID = getImageID();
	}
	run("FFT");
	FFTID = getImageID();
	setTool("line");
	waitForUser("Draw filter line (should pass by center and 2 peaks)");
	run("Measure");
	Angle = getResult("Angle",0);
	selectWindow("Results");
	run("Close");
	selectImage(FFTID);
	close();
	if(N>1)
	{
		selectImage("Slice");
		close();
	}
	waitForUser("Estimated angle: "+d2s(Angle,2));
	selectImage(ImageID);
}

// Initialization
setBatchMode(true);

// Create FFT filter
FFTWidth = pow(2,floor(log(maxOf(getWidth(),getHeight()))/log(2))+1);
newImage("Filter", "8-bit black", FFTWidth, FFTWidth, 1);
CX = FFTWidth/2;
CY = FFTWidth/2;
makePolygon(CX*(1+foffsX),CY,getWidth(),CY-fwdthY*FFTWidth,getWidth(),CY+fwdthY*FFTWidth);
run("Set...", "value=255");
makePolygon(CX*(1-foffsX),CY,0,CY-fwdthY*FFTWidth,0,CY+fwdthY*FFTWidth);
run("Set...", "value=255");
run("Select None");
run("Rotate... ", "angle=10 grid=1 interpolation=Bilinear");
run("Invert");
run("Gaussian Blur...", "sigma="+d2s(RadBlur,0));

// Filter image
selectImage(ImageID);
cnt = 0;
for(i=0;i<Iter;i++)
{
	for(s=1;s<=N;s++)
	{
		setSlice(s);
		run("Custom Filter...", "filter=Filter");
		cnt++;
		showProgress(cnt/(Iter*N));
	}
}

// Cleanup
selectImage("Filter");
close();
setBatchMode("exit & display");