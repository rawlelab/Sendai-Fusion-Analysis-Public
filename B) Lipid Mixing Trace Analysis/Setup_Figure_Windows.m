function [FigureHandles] = Setup_Figure_Windows(Options)

if strcmp(Options.DisplayFigures,'y')
    FigureHandles.GradientWindow = figure(23);
    %     set(FigureHandles.GradientWindow, 'Position', [1    79   560   420]);
        set(FigureHandles.GradientWindow, 'Position', [1 52 450 318]);
    FigureHandles.DiagnosticWindow = figure(24);
        set(FigureHandles.DiagnosticWindow, 'Position', [430 386 424 310]);
    FigureHandles.TraceWindow = figure(1);
        set(FigureHandles.TraceWindow, 'Position', [2 389 447 316]);
        
    if strcmp(Options.DisplayCurrentVirusSpot,'y') || strcmp(Options.DisplayColoredVirusesAtEnd,'y')
        FigureHandles.ImageWindow = figure(2);
        set(FigureHandles.ImageWindow, 'Position', [427    64   447   316]);
    end
else
    FigureHandles = [];
end

end