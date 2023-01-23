// This macro aims to open all CZI files from a folder into a Hyperstack and perform registration on the first channel.
// This macro runs HyperStackReg, developped by Ved P. Sharma (https://github.com/ved-sharma/HyperStackReg)
// Macro is turned into a Macro Toolset from version 0.1.1. 
// Re-order the dimension added in version 0.1.2
// Please remember to cite the authors

// Macro author R. De Mets
//Version : 0.1.2, 22/02/2022

var screenH = screenHeight;
var screenW = screenWidth;

macro "Hyperstack Reg Meta Button Action Tool - Cf00D73D74D75D76D77D78D83D84D85D86D87D88D93D94D95D96D97D98Da3Da4Da5Da6Da7Da8Db3Db4Db5Db6Db7Db8Dc3Dc4Dc5Dc6Dc7Dc8C55fD28D29D2aD2bD2cD2dC096D5cD6cD7cD8cCfffD00D01D02D03D04D05D06D07D08D09D0aD0bD0cD0dD0eD0fD10D11D12D13D14D15D16D17D18D19D1aD1bD1cD1dD1eD1fD20D21D22D23D24D25D2fD30D31D32D33D34D3fD40D41D42D43D4fD50D51D52D5fD60D6fD70D7fD80D8fD90D9fDa0DadDaeDafDb0DbdDbeDbfDc0DccDcdDceDcfDd0DdaDdbDdcDddDdeDdfDe0De1De9DeaDebDecDedDeeDefDf0Df1Df2Df3Df4Df5Df6Df7Df8Df9DfaDfbDfcDfdDfeDffC1f0D6bD7bD8bD9bCaafD3eD4eD5eD6eD7eD8eC1e1D47C66fD27D9dC15cD37Cf60D64D65D66D67D68CccfD2eCfeeDd1C02dD3cC2f0DabCfb3D54Cf33Dd8Cf80D69CccfD9eCffeD44C096D4cC1f0D5bCfa2DbaCf22D72Cf60D79D89D99Da9Db9CfeeDe2De3De4De5De6De7De8C00fD3dD4dD5dD6dD7dD8dCda0D6aD7aD8aD9aCfddD71D81D91Da1Db1Dc1Cf86D63Cda0DaaCeefD26CfffD61C2c6D9cCf11D82D92Da2Db2Dc2Cca0D56D57D58D59CfaaD62Cf44Dd2C03cD38D39D3aD3bC0e1D48D49D4aCbecD36Cf22Dd3Dd4Dd5Dd6Dd7Cf96Dc9Cda1D55CfffDcbC1f1D46Cab0D5aCfdaDcaC0e1D4bCcfbDbbC6f5D45CfbbDd9CdfdD35DbcC6f6DacCfebD53"{

run("Close All");
dirS = getDirectory("Choose source Directory");
dirD = getDirectory("Choose destination Directory");
dyes = open_file(dirS);
// Run HyperStackReg with Affine transformation based on the First channel only
run("HyperStackReg ", "transformation=Affine channel1 show");

create_dialog_box(dyes);
title_register = pick_channels(dyes);
save_metadata(dirD, title_register);
}



function open_file(dirS){
		
	pattern = ".*"; // for selecting all the files in the folder
	
	filenames = getFileList(dirS);
	count = 0;
	
	// Open each file and collect information about the dye from the title
	// Title format must be as followed : anything_dye1_dye2_dye3.czi
	for (i = 0; i < filenames.length; i++) {
		currFile = dirS+filenames[i];
		if(endsWith(currFile, ".czi") && matches(filenames[i], pattern)) { // process czi files matching regex
			open(currFile);
			
			title_long = getTitle();
			title_long_cut = split(title_long,"."); // cut the title at each . (anything_dye1_dye2_dye3)
			
			title_short = title_long_cut[title_long_cut.length-2];
			title_short_cut = split(title_short,"_"); // cut the title to get the dyes used, separated by _ (anything;dye1;dye2;dye3)
	
			// Create a dyes list based on the number of channels in the image
			if (count==0) {
				getDimensions(w, h, channels, slices, frames);
				index = 0;
				dyes = newArray(filenames.length*channels);
			}
			else {
				index = count*channels;
			}
			dyes[index] = "DAPI"; //Assuming the first channel is always DAPI, and the last 3 blocks of the title are the dyes
			dyes[index+1] = title_short_cut[title_short_cut.length-3]; // (dye1)
			dyes[index+2] = title_short_cut[title_short_cut.length-2]; // (dye2)
			dyes[index+3] = title_short_cut[title_short_cut.length-1]; // (dye3)
			count++;
		}	
	}
	
	// Concatenate all the open files together to make a Hyperstack
	run("Concatenate...", "all_open title=Hyperstack open");
	setLocation(0, 0)
	return dyes;
}	

function create_dialog_box(dyes){
	
	// GUI to choose which channel to keep
	Dialog.create("Channels to keep");
	ch_to_keep = newArray(dyes.length)
	for (ch = 0; ch < dyes.length; ch++) {
		Dialog.addCheckbox(dyes[ch], true); // default value is true for all
		
	}
	Dialog.show();
}

function pick_channels(dyes){
	
	// slice will contain the number of the slices to keep 
	slice = ""
	First_slice = 1;
	Title_register = getTitle();
	nb_ch = 1;
	
	// If the box is checked, edit the slice list and save the metadata
	for (ch = 0; ch < dyes.length; ch++) {
		if (Dialog.getCheckbox()) {
			temp_ch = ch+1;
			if (First_slice){ // First slice to keep shouldnt have ,
				slice = slice+temp_ch;
				First_slice = 0;
			}
			else{
				slice = slice +","+temp_ch; // Add , to the slice to keep
			}
			if (nb_ch<10) {
				List.set("Channel 0"+nb_ch,dyes[ch]);
			}
			else {
				List.set("Channel "+nb_ch,dyes[ch]);
			}
			nb_ch++;
		}
	}
	
	setLocation(screenW/4, 0);
	// Convert Hyperstack to a single Stack and keep the slices ticked
	run("Duplicate...", "duplicate");
	Title_temp = getTitle();
	run("Hyperstack to Stack");
	run("Make Substack...", "  slices="+slice);
	run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
	close(Title_temp);
	return Title_register;
}


function save_metadata(dirD, Title_register){
	
	// Set the metadata and save the file to the Output folder
	setMetadata("Info",List.getList());
	rename(Title_register);
	saveAs("Tiff", dirD+getTitle());
	setLocation(screenW/2, 0);	
	
}
