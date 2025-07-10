function Display_Current_Virus_Image(Options,FindingImage,CurrentVirusData,FusionData,FigureHandles,InputFlag,FrameNumToFindParticles)

    if strcmp(InputFlag,'Before Analysis')

        set(0,'CurrentFigure',FigureHandles.ImageWindow);
            hold off
            imshow(FindingImage, [Options.MinImageShow, Options.MaxImageShow], 'InitialMagnification', 'fit','Border','tight');
            title(strcat('Finding Image, Fr = ', num2str(FrameNumToFindParticles)));
            hold on

        if strcmp(CurrentVirusData.IsVirusGood,'y')
            LineColor = 'g-';
        else
            LineColor = 'r-';
        end
        set(0,'CurrentFigure',FigureHandles.ImageWindow);
            plot(CurrentVirusData.BoxCoords(:,1),CurrentVirusData.BoxCoords(:,2),LineColor)
            hold on
            drawnow

    elseif strcmp(InputFlag,'After Analysis')
        % Maybe set up in the future? Perhaps if we want the color to change depending on the designation?
    end

end