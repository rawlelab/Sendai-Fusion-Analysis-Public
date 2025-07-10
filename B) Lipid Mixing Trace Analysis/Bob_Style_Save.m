function [Options] = Bob_Style_Save(CurrDataFileName,Options)
IndexofTraces = strfind(CurrDataFileName,'_ExtractedTraces');
            if ~isempty(IndexofTraces)
                CurrLabel = CurrDataFileName(1:IndexofTraces(1)-1);
            else 
                CharFileName = char(CurrDataFileName);
                IdxOfDot = find(CharFileName=='.');
                FileNameWOExt = CharFileName(1:IdxOfDot(1)-1);
                FileNameWOExt = FileNameWOExt(1:min(6,length(FileNameWOExt)));
                CurrLabel = strcat(FileNameWOExt);
            end
        
if strcmp(Options.UseFullFileNameAsLabel,'y')
    CharFileName = char(CurrDataFileName);
    IdxOfDot = find(CharFileName=='.');
    FileNameWOExt = CharFileName(1:IdxOfDot(1)-1);
    CurrLabel = strcat(FileNameWOExt);
end

Options.Label = strcat(CurrLabel,Options.ExtraLabel);

end