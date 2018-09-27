clc;
close all;
format long g; % sets output format to long decimal
%profile on % was using for performance breakdown during optimization


location = pwd; % returns path to current folder
file = 'traffic.wmv'; % video file
%file = 'traffic2.wmv'; % alt file
fileLoc = 'location, file'; % location of video file

% checking for file and its existence
if ~exist(fileLoc, 'file') % if the file does not exist
    fileLoc = file; % using the path to the folder to search for file 
    if ~exist(fileLoc, 'file') % if the file STILL does not exist
        warningMSG = sprintf('%s cannot be found.', fileLoc); % warning that the file cannot be found
        % uiwait blocks program execution until the figure is deleted
        % warndlg creates a warning dialogue box that will display 'warningMSG'
        uiwait(warndlg(warningMSG));
        return;
    end
end

videoSource = VideoReader(fileLoc); % creating object using imported video

numFrames = videoSource.NumberOfFrames; % getting the number of frames from the source video

% thresh values for traffic
hThresh = [0.7, 1.0]; % hue threshold containing red values
sThresh = [0.1, 0.7]; % saturation threshold set to red values of saturation .1 thru .7
vThresh = [100, 220]; % value threshold set to red values of exposure values 100 thru 220

% thresh values for traffic2
% hThresh = [0.1, 0.5]; % hue threshold for green values
% sThresh = [0.2, 0.7];
% vThresh = [100, 200];

main = figure('Name', 'Find Red Car', 'NumberTitle', 'off'); % configuring main window

for n = 1:numFrames % going through every frame of the video 
    %---------------------- Get and display current frame ----------------------%
    currentFrame = read(videoSource, n); % stepping through each frame from 1:n
    subplot(1, 2, 1); %subplot(1, 3, 1); % plot current frame
    imshow(currentFrame); % show current frame
    axis off;
    caption = sprintf('Frame #%d of %d', n, numFrames); % displays current frame count
    title(caption);
    drawnow; % update figure every frame
    %----------------------------------------------------------------------------%
    
    %---------------------- HSV and Binary mask ----------------------%
    hsvIMG = rgb2hsv(double(currentFrame)); % converting RGB frame to double HSV frame
    hueVal = hsvIMG(:, :, 1); % assigning hue value from hsvIMG
    satVal = hsvIMG(:, :, 2); % assigning saturation value from hsvIMG
    valVal = hsvIMG(:, :, 3); % assigning value (exposure) value from hsvIMG
    
    % hsvM (HSV mask) is a merger of all of the xVal values that meet all 3
        % requirements
	hsvM = (hueVal >= hThresh(1) & hueVal <= hThresh(2)) & (satVal >= sThresh(1) & satVal <= sThresh(2)) & (valVal >= vThresh(1) & valVal <= vThresh(2));
    
	% Filter out small objects to avoid counting cars multiple times
        % Objects smaller than 150px are removed
        % Converts accepted xVal values to white in the binary image (bw) 
	hsvM = bwareaopen(hsvM, 150); %use for traffic
    %hsvM = bwareaopen(hsvM, 4000); %use for traffic2
    
    % function that connects white values within a radius in the binary mask
        % creates 60px x 60px connection radius in hsvM to eliminate any
        % stray unconnected white groups
    se = strel('square', 60); %use for traffic
    %se = strel('square', 200); %use for traffic2
    hsvM = imclose(hsvM, se);
    %-----------------------------------------------------------------%  
    
    %---------------------- Binary Mask Demo ----------------------%
% 	subplot(1, 2, 2);
% 	imshow(hsvM);
% 	axis off;
% 	title('Binary Mask');
% 	drawnow;
    %--------------------------------------------------------------%
    
    %---------------------- Tracking ----------------------%
    % bwlabel assigns each region its own number. This allows the regions
        % to be counted as unique areas
    [labelHSVM, numRegions] = bwlabel(hsvM); % defining labelHSVM and numRegions
    
    if numRegions >= 1
        % populating stats with values that will be used to track the 'car'
            % regions in the binary image
		stats = regionprops(labelHSVM, 'BoundingBox', 'Centroid');
        
		% Delete old rects each frame
		if exist('rect', 'var')
			delete(rect);
        end
        
        % Car tracking frame
		subplot(1, 2, 2); %subplot(1,3,2); % Original image w/ tracking
		imshow(currentFrame);
		axis off;
		hold on;
		caption = sprintf('%d objects found in frame #%d of %d', numRegions, n, numFrames);
		title(caption);
        % forces the subplot to update every iteration
		drawnow;
		
		% Loop for bounding passed areas
		for x = 1:numRegions
			% setting location for bounding box(es)
			myBounds = stats(x).BoundingBox;
            % setting location for centroid(s)
			myCentroids = stats(x).Centroid;
            % creating rectangles using bounds location
                % x parameter allows multiple rects to exists
                % size of rect is determined by its paired bounds
			rect(x) = rectangle('Position', myBounds, 'EdgeColor', 'g', 'LineWidth', 1); % box
            % creating crosshairs with myCentroid location data
                % 1 and 2 refer to x,y coords
			plot(myCentroids(1), myCentroids(2), 'w+', 'MarkerSize', 5, 'LineWidth', 1); % crosshair
        end
		hold off
    end 
    %------------------------------------------------------%
end

%profile viewer