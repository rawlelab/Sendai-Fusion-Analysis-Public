function [ImageWidth,NumFramesActuallyAnalyzed,ImageHeight,BitDepth,VideoMatrix,...
    BWVideoMatrix,ThresholdToFindParticles,TotalVideoIntensity,AverageVideoIntensity,...
    RoughBackground,FigureHandles,TimeVector,VideoTimeVector,StandardBindTime,FindingImage] =...
    Create_Video_Matrix_Auto_Time_Vector(VideoFilePath,...
    Options)

    % First, we use the bio formats open function to get the data, and then pull out 
    % the relevant metadata by creating the appropriate key. If you want to mess 
    % around with this, you will need to look at the bio formats help documentation 
    % for OME.TIF files
    
    data = bfopen(VideoFilePath);

    metadata = data{1, 2};
    if strcmp(Options.CombineMultipleVideos,'y')
        NumFramesInFullVideo = Options.NumFrames(1);
    else
        NumFramesInFullVideo = size(data{1,1},1);
    end
    
    StartFrameNumber = Options.StartAnalysisFrameNumber;
    
    if ~strcmp(Options.CombineMultipleVideos,'y') && data{1,1}{NumFramesInFullVideo,1}(1,1) == 0
        % If the time lapse was cut short, the metadata will still try to find all 
        % of the images for the length that was originally set.  You'll end up with 
        % zeros in any image that was not collected. Therefore, we need to exclude 
        % those from the analysis. We will do that below.

        CurrentNonZeroFrameNumberTally = 0;
        for i = 1:NumFramesInFullVideo
            if data{1,1}{i,1}(1,1) ~= 0
                CurrentNonZeroFrameNumberTally = CurrentNonZeroFrameNumberTally + 1;
            else 
                break
            end
        end
        NumFramesInFullVideo = CurrentNonZeroFrameNumberTally;
    end
    
    if NumFramesInFullVideo < 101
        for i = 1:NumFramesInFullVideo
            if i < 11
                VideoTimeVector(i) = str2double(metadata.get(strcat('Plane #','0', num2str(i-1),...
                ' ElapsedTime-ms')));
                % VideoTimeVector is the time of the entire video, 
                % including any frames which are ignored in the trace analysis
            else
                VideoTimeVector(i) = str2double(metadata.get(strcat('Plane #', num2str(i-1),...
                ' ElapsedTime-ms')));
            end
        end
        BitDepth = str2double(metadata.get(strcat('Plane #00 BitDepth')));
        ImageWidth = str2double(metadata.get(strcat('Plane #00 Width'))); %in pixels
        ImageHeight = str2double(metadata.get(strcat('Plane #00 Height'))); %in pixels
        
    else
        for i = 1:NumFramesInFullVideo
            if i < 11
                VideoTimeVector(i) = str2double(metadata.get(strcat('Plane #','00', num2str(i-1),...
                ' ElapsedTime-ms')));
            elseif i >= 11 && i < 101
                VideoTimeVector(i) = str2double(metadata.get(strcat('Plane #','0', num2str(i-1),...
                ' ElapsedTime-ms')));
            else
                VideoTimeVector(i) = str2double(metadata.get(strcat('Plane #',num2str(i-1),...
                ' ElapsedTime-ms')));
            end

        end

        BitDepth = str2double(metadata.get(strcat('Plane #000 BitDepth')));
        ImageWidth = str2double(metadata.get(strcat('Plane #000 Width'))); %in pixels
        ImageHeight = str2double(metadata.get(strcat('Plane #000 Height'))); %in pixels
    end
  
    % Depending on the situation, we truncate the time vector. TimeVector is the time associated with the actual
    % trace being measured (so excluding any frames which are ignored in the trace extraction). 
    % This will be the same length or less than VideoTimeVector
        if strcmp(Options.DetermineBindingTimeFromTimestamp, 'y')
            % If we are determining the time zero from an image timestamp, then 
            % we do that here. We will assume that the standard bind time is 0, 
            % and make that so by subtracting the time zero frame
            StandardBindTime = 0;
            TimeVector = VideoTimeVector - VideoTimeVector(Options.TimeZeroFrameNumber);
            TimeVector = TimeVector(StartFrameNumber:end); 
                % exclude the first image(s) from the trace analysis, since it was 
                % only used as a time zero marker, or otherwise excluded
        else
            StandardBindTime = Options.BindingTime;
            TimeVector = VideoTimeVector - VideoTimeVector(1);
        end

        if isnan(Options.FrameNumberLimit) || strcmp(Options.CombineMultipleVideos,'y')
        else
            if Options.FrameNumberLimit > NumFramesInFullVideo
                disp('Oops! You manually chose a frame number limit larger than the number of frames in the video.  Double check your options.');
            end
            NumFramesInFullVideo = Options.FrameNumberLimit;
            TimeVector = TimeVector(1:NumFramesInFullVideo);
        end
  
        NumFramesActuallyAnalyzed = length(StartFrameNumber:NumFramesInFullVideo);
        
        % Convert time vector to minutes (default is ms)
        TimeVector = TimeVector/(1000*60);

    % Now we pre-allocate data to store our video matrix, and display our finding image
        VideoMatrix = zeros(ImageHeight, ImageWidth, NumFramesActuallyAnalyzed, 'uint16');
        
        %Create a logical matrix the same size as the video matrix.
        BWVideoMatrix = VideoMatrix > 0; 
        
        %Preallocate various vectors as well
        ThresholdToFindParticles = zeros(NumFramesActuallyAnalyzed,1);
        TotalVideoIntensity = zeros(NumFramesActuallyAnalyzed,1);
        AverageVideoIntensity = zeros(NumFramesActuallyAnalyzed,1);
        RoughBackground = zeros(NumFramesActuallyAnalyzed,1);
        
        %Set up figures
        [FigureHandles] = Setup_Figures(Options);
        
        % Display the finding image first thing. This will help you determine 
        % if you have set a good threshold.
            VideoInfo.Width =  ImageWidth; %in pixels
            VideoInfo.Height =  ImageHeight; %in pixels
            VideoInfo.BitDepth = BitDepth;
        [FindingImage] = Display_Finding_Image(VideoFilePath,Options,VideoInfo,FigureHandles,data,StartFrameNumber);
        
    %This for loop populates the VideoMatrix with the data from each image
    %in the video.  The 1st two dimensions are the x,y of the image plane and the 3rd 
    %dimension is the frame number. We adjust for the start frame to account for the times when we exclude 
    %the first frame(s) during automatic time extraction.
    
        NewFrameNum = 0;
    for b = StartFrameNumber:NumFramesActuallyAnalyzed + (StartFrameNumber-1)
        CurrentFrameImage = data{1, 1}{b, 1};
        
        NewFrameNum = NewFrameNum + 1;
        
        VideoMatrix(:,:,NewFrameNum) = CurrentFrameImage;
                            
        % For each frame, the background intensity, average intensity, and 
        % integrated intensity are calculated. The threshold for each image 
        % is also calculated (this would be used if particles were being found 
        % or tracked in each image, which is currently not being done).
        RoughBackground(NewFrameNum) = mean(median(CurrentFrameImage));
        TotalVideoIntensity(NewFrameNum) = sum(sum(CurrentFrameImage));
        AverageVideoIntensity(NewFrameNum) = mean(mean(CurrentFrameImage));
        ThresholdToFindParticles(NewFrameNum) = (RoughBackground(NewFrameNum) + Options.Threshold)/2^BitDepth;
        
        %We apply the threshold to create a big logical matrix
        CurrThresh = ThresholdToFindParticles(NewFrameNum);
        BWVideoMatrix(:,:,NewFrameNum) = im2bw(CurrentFrameImage, CurrThresh);
        BWVideoMatrix(:,:,NewFrameNum) = bwareaopen(BWVideoMatrix(:,:,NewFrameNum), Options.MinParticleSize, 8);
        
        %Display the progress of loading the frames
        if rem(b,20)==0
            set(0,'CurrentFigure',FigureHandles.CurrentTraceWindow);
            title(strcat('Compiling Frame :', num2str(NewFrameNum),'/', num2str(NumFramesActuallyAnalyzed)));
            drawnow
        end
        
    end
    
    if strcmp(Options.CombineMultipleVideos,'y')
        
        for i= 2:Options.NumberOfVideosToCombine
            [VideoMatrix,RoughBackground,...
                TotalVideoIntensity,AverageVideoIntensity,ThresholdToFindParticles,...
                BWVideoMatrix,NumFramesActuallyAnalyzed,TimeVector] = ...
            Stitch_Next_Video(i,Options,VideoMatrix,RoughBackground,...
                TotalVideoIntensity,AverageVideoIntensity,ThresholdToFindParticles,...
                BWVideoMatrix,NumFramesActuallyAnalyzed,TimeVector,FigureHandles);
        end
  
    end
    
    
 end