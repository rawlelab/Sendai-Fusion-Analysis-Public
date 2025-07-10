function [Offset] = Determine_Pixel_Offset_Over_Time(VideoMatrix,BWVideoMatrix,...
            FigureHandles,Options)
    
    % Tell the user what is going on
    disp('   You selected "Options.DeterminePixelOffset = y"')
    disp('   So, please select a bright, isolated spot in Figure 1.')
    disp('     I will track it over time to determine the offset.')
    disp('     Pro tip: dont select a spot too close to the edge or you will get an error')
    

    %Manually choose the spot you want to analyze
    set(0,'CurrentFigure',FigureHandles.ImageWindow);
    [Pos.x,Pos.y] = ginput(1);

    disp('   Thanks. Tracking particle now.')
    
    Search_Radius = Options.SearchRadius;

    XStart = Pos.x; YStart = Pos.y;

    XOld = XStart; YOld = YStart;

    NumberFramesToAnalyze = size(VideoMatrix,3);
%     if isnan(Options.FrameNumberLimit)
%         NumberFramesToAnalyze = size(VideoMatrix,3);
%     else
%         NumberFramesToAnalyze = Options.FrameNumberLimit - (Options.StartAnalysisFrameNumber - 1);
%     end

    %Track the spot over time
    for CurrFrame = 1:NumberFramesToAnalyze

        ImAreaToSearch = VideoMatrix(...
                        round(YOld)-Search_Radius:round(YOld)+Search_Radius,...
                        round(XOld)-Search_Radius:round(XOld)+Search_Radius,...
                        CurrFrame);
        BWAreaToSearch = BWVideoMatrix(...
                        round(YOld)-Search_Radius:round(YOld)+Search_Radius,...
                        round(XOld)-Search_Radius:round(XOld)+Search_Radius,...
                        CurrFrame);

        VirusesFound = bwconncomp(BWAreaToSearch,8);
        NumVirusesFound = VirusesFound.NumObjects;

        if (NumVirusesFound == 0)
            %Means that it moves off the viewing area (or fully fuses)
            disp('   ---------Uh oh!!---------')
            disp('   Error-cant find virus. Maybe moved off viewing area or fused?')

            ErrorCantFindVirus
        end

        PropsOfVirusesFound = regionprops(VirusesFound, ImAreaToSearch, 'WeightedCentroid');

        if (NumVirusesFound == 1)
            XNew = PropsOfVirusesFound(1).WeightedCentroid(1)-Search_Radius-1+XOld;
            YNew = PropsOfVirusesFound(1).WeightedCentroid(2)-Search_Radius-1+YOld;
        elseif (NumVirusesFound > 1) %If there is more than one Virus found, use the one that is closest to the last measurement.
            DistToPrevCent = zeros(1,NumVirusesFound);
            for i = 1:NumVirusesFound
                XTest = PropsOfVirusesFound(i).WeightedCentroid(1)-Search_Radius-1+XOld;
                YTest = PropsOfVirusesFound(i).WeightedCentroid(2)-Search_Radius-1+YOld;
                DistToPrevCent(i) = sqrt((YTest-YOld)^2+(XTest-XOld)^2);
            end

            IdxVirusToUse = find(DistToPrevCent==min(DistToPrevCent));
            XNew = PropsOfVirusesFound(IdxVirusToUse).WeightedCentroid(1)-Search_Radius-1+XOld;
            YNew = PropsOfVirusesFound(IdxVirusToUse).WeightedCentroid(2)-Search_Radius-1+YOld;

        end

        XOld = XNew; YOld = YNew;
        Pos.y(CurrFrame) = YNew;
        Pos.x(CurrFrame) = XNew;

        
        %Plot out the tracking for diagnostic purposes
            figure(33)
            ImToShow = VideoMatrix(...
                           round(YStart)-2.5*Search_Radius:round(YStart)+2.5*Search_Radius,...
                           round(XStart)-2.5*Search_Radius:round(XStart)+2.5*Search_Radius,...
                           CurrFrame);
            imshow(ImToShow, [Options.MinImageShow, Options.MaxImageShow], 'InitialMagnification', 'fit');
            hold on;
            plot(XNew+2.5*Search_Radius+1-XStart,YNew+2.5*Search_Radius+1-YStart,'go')
            drawnow;


    end

    Offset.x = Pos.x - Pos.x(1);
    Offset.y = Pos.y - Pos.y(1);

    disp('   All done tracking. Moving on to trace extraction.')
    disp('   ...')
    
end