function Display_All_Analyzed_Viruses(Options,FindingImage,AnalyzedTraceData,FigureHandles,FrameNumToFindParticles)


    set(0,'CurrentFigure',FigureHandles.ImageWindow);
        hold off
        imshow(FindingImage, [Options.MinImageShow, Options.MaxImageShow], 'InitialMagnification', 'fit','Border','tight');
        title(strcat('Finding Image, Fr = ', num2str(FrameNumToFindParticles)));
        hold on
            
    for i = 1:length(AnalyzedTraceData)

        if strcmp(AnalyzedTraceData(i).Designation,'1 Fuse')
            LineColor = 'g-';
        elseif strcmp(AnalyzedTraceData(i).Designation,'Slow')
            LineColor = 'c-';
        elseif strcmp(AnalyzedTraceData(i).Designation,'No Fusion')
            LineColor = 'r-';
        elseif strcmp(AnalyzedTraceData(i).Designation,'Unbound')
            LineColor = 'y-';
        else
            LineColor = 'm-';
        end
        set(0,'CurrentFigure',FigureHandles.ImageWindow);
            plot(AnalyzedTraceData(i).BoxCoords(:,1),AnalyzedTraceData(i).BoxCoords(:,2),LineColor)
            hold on
            drawnow

    end

end