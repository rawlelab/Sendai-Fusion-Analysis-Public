function [FigureHandles] = Draw_Lines_on_Plot(FigureHandles,DockingData,FusionData,UniversalData,...
    TraceGradData)

set(0,'CurrentFigure',FigureHandles.TraceWindow)
hold on
LineToPlot = ylim;

if strcmp(FusionData.Designation,'2 Fuse')
    XToPlot = [FusionData.FuseFrameNumbers(1), FusionData.FuseFrameNumbers(1)];
    plot(XToPlot,LineToPlot,'b--')
    XToPlot = [FusionData.FuseFrameNumbers(2), FusionData.FuseFrameNumbers(2)];
    plot(XToPlot,LineToPlot,'b--')

    Title = strcat('Bind = ',num2str(UniversalData.StandardBindTime),...
        '; Dock = ',num2str(DockingData.StopFrameNum),...
        '; 1fuse = ', num2str(FusionData.FuseFrameNumbers(1)),...
        '; 2fuse = ', num2str(FusionData.FuseFrameNumbers(2)),...
        '; BindtoF = ', num2str(FusionData.BindtoFusionTime(1)));
    title(Title);
    
elseif strcmp(FusionData.Designation,'1 Fuse')
    XToPlot = [FusionData.FuseFrameNumbers(1), FusionData.FuseFrameNumbers(1)];
    plot(XToPlot,LineToPlot,'b--')
    Title = strcat('Bind = ',num2str(UniversalData.StandardBindTime),...
        '; Dock = ',num2str(DockingData.StopFrameNum),...
        '; 1fuse = ', num2str(FusionData.FuseFrameNumbers(1)),...
        '; BindtoF = ', num2str(FusionData.BindtoFusionTime(1)));
    title(Title);
    
elseif strcmp(FusionData.Designation,'No Fusion')
    Title = strcat('Bind = ',num2str(UniversalData.StandardBindTime),...
        '; Dock = ',num2str(DockingData.StopFrameNum));
    title(Title);
    
elseif strcmp(FusionData.Designation,'Slow')
    TraceRunMedian = TraceGradData.TraceRunMedian;
    DiffPosClusterData = TraceGradData.DiffPosClusterData;
    SlowFusePosFrameNumbers = TraceRunMedian.FrameNumbers(DiffPosClusterData.ClusterStartIndices);
    for d = 1:length(SlowFusePosFrameNumbers)
        XToPlot = [SlowFusePosFrameNumbers(d), SlowFusePosFrameNumbers(d)];
        plot(XToPlot,LineToPlot,'b--')
    end
    
elseif strcmp(FusionData.Designation,'Unbound')
    TraceRunMedian = TraceGradData.TraceRunMedian;
    DiffNegClusterData = TraceGradData.DiffNegClusterData;
    UnboundFuseNegFrameNumbers = TraceRunMedian.FrameNumbers(DiffNegClusterData.ClusterStartIndices);
    for d = 1:length(UnboundFuseNegFrameNumbers)
        XToPlot = [UnboundFuseNegFrameNumbers(d), UnboundFuseNegFrameNumbers(d)];
        plot(XToPlot,LineToPlot,'k--')
    end      
    
    DiffPosClusterData = TraceGradData.DiffPosClusterData;
    SlowFusePosFrameNumbers = TraceRunMedian.FrameNumbers(DiffPosClusterData.ClusterStartIndices);
    for d = 1:length(SlowFusePosFrameNumbers)
        XToPlot = [SlowFusePosFrameNumbers(d), SlowFusePosFrameNumbers(d)];
        plot(XToPlot,LineToPlot,'g--')
    end
end

if strcmp(DockingData.IsMobile ,'y')
    XToPlot = [DockingData.StopFrameNum, DockingData.StopFrameNum];
    plot(XToPlot,LineToPlot,'k--')
end
     
hold off
drawnow
end