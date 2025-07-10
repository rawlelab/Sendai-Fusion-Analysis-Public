function [TraceGradData,FusionData] = Is_Slow_Fusion(TraceGradData,FusionData,...
        DockingData,DetectionOption,Options,FuseSpikeFrameNumbers)

% We use the difference trace test to identify slow fusion events, which 
% appear to occur over many frames, rather than as a sharp event. Because 
% the difference trace will also identify fast events, we have to do a 
% cross comparison to make sure that we don't identify a fast event as 
% a slow event. There are two different methods of analyzing the difference 
% trace test data - Usual and Cluster Analysis. Right now the Cluster 
% Analysis is more reliable (Bob, December 2016).

% UPDATE: this has been optimized for tethered vesicle fusion with Sendai virus. 
% If you are using this for any other reason, you will need to change details below. 
% (Bob, January 2022)

% Pre-define some variables
FilteredDiffTraceNeg = TraceGradData.FilteredDiffTraceNeg;
FilteredDiffTracePos = TraceGradData.FilteredDiffTracePos;
RangeToFilterDifference = Options.NumberFramesBackToSubtract;
TraceRunMedian = TraceGradData.TraceRunMedian;

if strcmp(DetectionOption,'Usual Trace Analysis')
    NumSlowFusionEventsPosDetected = sum(FilteredDiffTracePos);
    NumSlowFusionEventsNegDetected = sum(FilteredDiffTraceNeg);
    SlowFusePosFrameNumbers = TraceRunMedian.FrameNumbers(FilteredDiffTracePos);
    SlowFuseNegFrameNumbers = TraceRunMedian.FrameNumbers(FilteredDiffTraceNeg);

    if NumSlowFusionEventsNegDetected == 0 && NumSlowFusionEventsPosDetected == 0
    else
        if NumSlowFusionEventsNegDetected > 0
            if isempty(FusionData.FuseFrameNumbers)
                FusionData.Designation = 'Slow';
            else
                for j= 1:NumSlowFusionEventsNegDetected 
                    % If the potential slow fusion event is nearby a fusion
                    % event that was already detected, assume that everything
                    % is fine and move on. Otherwise, classify this trace as a
                    % slow fusion event.
                    DistanceToFastFusionEvents = abs(FusionData.FuseFrameNumbers - SlowFuseNegFrameNumbers(j));
                    EventsCloseBy = DistanceToFastFusionEvents <= RangeToFilterDifference;
                    if sum(EventsCloseBy) == 0
                        FusionData.Designation = 'Slow';
                        break
                    end
                end
            end

        end

        if NumSlowFusionEventsPosDetected > 0
            if isempty(FusionData.FuseFrameNumbers) && isempty(DockingData.StopFrameNum)
                FusionData.Designation = 'Slow';
            else
                for j= 1:NumSlowFusionEventsPosDetected
                    % If the potential slow fusion event is nearby a fusion or
                    % docking event that was already detected, assume that everything
                    % is fine and move on. Otherwise, classify this trace as a
                    % slow fusion event.
                    OtherEventFrameNumbers = [DockingData.StopFrameNum FusionData.FuseFrameNumbers];
                    DistanceToOtherEvents = abs(OtherEventFrameNumbers - SlowFusePosFrameNumbers(j));
                    EventsCloseBy = DistanceToOtherEvents <= RangeToFilterDifference;
                    if sum(EventsCloseBy) == 0
                        FusionData.Designation = 'Slow';
                        break
                    end
                end
            end

        end
    end

elseif strcmp(DetectionOption,'Cluster Analysis')
    
    ClusterRange = Options.NumFramesBetweenDifferentClusters;
    [TraceGradData.DiffPosClusterData] = Analyze_Trace_Clusters(FilteredDiffTracePos,ClusterRange);
    [TraceGradData.DiffNegClusterData] = Analyze_Trace_Clusters(FilteredDiffTraceNeg,ClusterRange);
    
    DiffNegClusterData = TraceGradData.DiffNegClusterData;
    DiffPosClusterData = TraceGradData.DiffPosClusterData;
    
    NumSlowFusionEventsPosDetected = DiffPosClusterData.NumberOfClusters;
    NumSlowFusionEventsNegDetected = DiffNegClusterData.NumberOfClusters;
    SlowFusePosFrameNumbers = TraceRunMedian.FrameNumbers(DiffPosClusterData.ClusterStartIndices);
    SlowFuseNegFrameNumbers = TraceRunMedian.FrameNumbers(DiffNegClusterData.ClusterStartIndices);
    ClusterSizesPos = DiffPosClusterData.ClusterSizes;
    ClusterSizesNeg = DiffNegClusterData.ClusterSizes;
    
    NumberFramesFastFusionCuttoffPos = Options.NumberFramesBackToSubtract + Options.ClusterSizePosConsideredFastFusion;
    NumberFramesFastFusionCuttoffNeg = Options.NumberFramesBackToSubtract + Options.ClusterSizeNegConsideredFastFusion;
    
    NumberBigClustersPos = sum(ClusterSizesPos >= NumberFramesFastFusionCuttoffPos);
    NumberBigClustersNeg = sum(ClusterSizesNeg >= NumberFramesFastFusionCuttoffNeg);

    if NumSlowFusionEventsNegDetected == 0 && NumSlowFusionEventsPosDetected == 0
        % If no slow events are detected, then do nothing, keep previous designation
    elseif NumberBigClustersPos > 0 || NumberBigClustersNeg > 0
        FusionData.Designation = 'Slow';
        % If we have at least 1 big cluster, that means we have a slow event somewhere, so we will
        % classify it as such. 
    else
        % If we get to this point, this means that we have no big clusters, and at least one "slow" 
        % event (pos or neg) below the fast fusion cutoff threshold.  We will investigate all of the possibilities below
        if NumSlowFusionEventsNegDetected > 0
            % First we investigate the negative events, because if we have a large negative transition 
            % that isn't part of a spike, that means we have an unbinding event. In that case, we don't
            % need to consider the positive events
            if isempty(FusionData.FuseFrameNumbers)
                % First we consider the case where we haven't already identified any fusion events 
                % from the previous analysis
                
                if NumSlowFusionEventsPosDetected == 0
                    % If there is at least one negative event, and if there are 
                    % no positive events, then this is an unbinding
                    % event
                        FusionData.Designation = 'Unbound';
                    
                elseif NumSlowFusionEventsPosDetected > 0
                    % If on the other hand there is at least one positive event, we need to 
                    % consider each neg event in turn to determine if it is part of a spike, or on its own
                    for j= 1:NumSlowFusionEventsNegDetected 
                        % If the potential negative slow fusion event is nearby a positive fusion
                        % event already detected, then assume it is a spike, and we leave the classification as 
                        % is from the previous analysis. Otherwise, classify as unbinding event.
                        DistanceToPosFusionEvents = abs(SlowFusePosFrameNumbers - SlowFuseNegFrameNumbers(j));
                        EventsCloseBy = DistanceToPosFusionEvents <= RangeToFilterDifference;
                        if sum(EventsCloseBy) == 0
                            FusionData.Designation = 'Unbound';
                            break
                            % We exit out of the for loop the first time this condition is 
                            % met because it doesn't matter how many other events there are 
                            % if at least one of them is isolated
                        end
                    end
                    
                    if ~strcmp(FusionData.Designation,'Unbound')
                        FusionData.Designation = 'No Fusion'; 
                        % If none of the above conditions are met, we classify this as "No fusion" (should all be spike events)
                        % Note that we will still check the positive events below in case there are extra positive events 
                        % which would indicate fusion
                        % This should be redundant (the previous analysis should have 
                        % classified this as "No Fusion"), but we will do this just to be safe
                    end
                    
                else 
                    FusionData.Designation = 'Slow';
                    % I don't think we should ever reach this condition, but 
                    % just to be safe we will designate this as weird (a.k.a. "Slow")
                end
            else
                % Now we consider the case where we have detected at least 1 negative event, 
                % and we have identified fusion events in the previous
                % analysis. In this case, the previously identified fusion events should 
                % also show up as positive events here. So we will do the same analysis 
                % as above to determine if the negative event is close enough to a positive 
                % event to call it a spike (in which case it probably would have been weeded 
                % out in the previous analysis). if not, then we have an unbinding event
                for j= 1:NumSlowFusionEventsNegDetected 
                    % If the potential negative slow fusion event is nearby a positive fusion
                    % event already detected, then assume it is a spike, and we leave the classification as 
                    % is from the previous analysis. Otherwise, classify as unbinding event.
                    DistanceToPosFusionEvents = abs(SlowFusePosFrameNumbers - SlowFuseNegFrameNumbers(j));
                    EventsCloseBy = DistanceToPosFusionEvents <= RangeToFilterDifference;
                    if sum(EventsCloseBy) == 0
                        FusionData.Designation = 'Unbound';
                        break
                        % We exit out of the for loop the first time this condition is 
                        % met because it doesn't matter how many other events there are 
                        % if at least one of them is isolated
                    end             
                end   
            end
        end

        if NumSlowFusionEventsPosDetected > 0  && ~strcmp(FusionData.Designation,'Unbound')
            % Now we consider the positive events. We ignore anything we have already classified 
            % as "Unbound". Otherwise, even if there were a negative event, it should have already 
            % been classified as a spike, and we will verify that below. What we are looking for is 
            % positive events that aren't part of spikes, which would indicate fusion.
            
            if isempty(FusionData.FuseFrameNumbers) && isnan(DockingData.StopFrameNum)
                %  First we consider the case where no fusion events or binding events 
                %  have been classified in the previous analysis
                if NumSlowFusionEventsPosDetected == 1 &&...
                        NumSlowFusionEventsNegDetected == 0 &&...
                        ClusterSizesPos > 1
                    %  If there is only a single positive event, then this is a 
                    %  clear-cut single fusion event. We also check whether the cluster 
                    %  size is bigger than 1 (transient spike usually gives cluster size of 1, 
                    %  whereas real fusion events should be at least a couple)
                    
                    FusionData.Designation = '1 Fuse';
                    FusionData.FuseFrameNumbers = SlowFusePosFrameNumbers(1);
                    
                elseif NumSlowFusionEventsPosDetected == 1 &&...
                        NumSlowFusionEventsNegDetected == 0 &&...
                        ClusterSizesPos == 1
                    % If there is only one event detected but the cluster size is 1, assume it 
                    % is a spike, so this should be classified as "No Fusion"
                    
                    FusionData.Designation = 'No Fusion';
                    
                elseif NumSlowFusionEventsNegDetected > 0
                    % If on the other hand there is at least one negative event, 
                    % then we exclude any positive events that are nearby negative 
                    % events as spikes and only consider the rest. if we have 1 left 
                    % over, then it is a single fusion event, otherwise we have multiple 
                    % positive events left over and reclassify as weird (a.k.a. "slow")
                    for j= 1:NumSlowFusionEventsPosDetected 
                        % We look at each positive event in turn
                        DistanceToNegFusionEvents = abs(SlowFuseNegFrameNumbers - SlowFusePosFrameNumbers(j));
                        EventsCloseBy = DistanceToNegFusionEvents <= RangeToFilterDifference;
                        if sum(EventsCloseBy) == 0 && ClusterSizesPos(j) > 1
                            % If the positive event is nearby a neg
                            % event already detected, and the cluster size is small
                            % enough, then assume it is fine (transient spike usually 1 frame cluster). Otherwise, classify.
                            if strcmp(FusionData.Designation,'1 Fuse')
                                % Check to see if we have already 
                                % classified this as a 1 Fuse event. If so, this means we have now 
                                % found another fusion event, so we will call this unusual (a.k.a. "slow")
                                FusionData.Designation = 'Slow';
                            else
                                % Otherwise, this means that this is the first fast isolated fusion event, 
                                % so we will designate it as a 1 Fuse event. But we will still scan the 
                                % rest of the events to see if there are
                                % any others
                                FusionData.Designation = '1 Fuse';
                                FusionData.FuseFrameNumbers = SlowFusePosFrameNumbers(j);
                            end
                        end
                    end
                    
                    if ~strcmp(FusionData.Designation,'1 Fuse')
                        FusionData.Designation = 'No Fusion'; 
                        % If none of the above conditions are met, we classify this as "No fusion" (should all be spike events)
                    end
                    
                else 
                    FusionData.Designation = 'Slow';
                    % We should only reach here if we have multiple positive fusion events and no negatives.
                    % We will designate this as weird (a.k.a. "Slow")
                end
            else
                % Now we consider the case where the previous analysis has 
                % identified a fusion (or a docking/binding event). 

                for j= 1:NumSlowFusionEventsPosDetected
                    % If the potential slow fusion event is nearby a fusion or
                    % docking event that was already detected
                    % assume that we are just picking up the same event, so we move on (i.e. keep previous designation). 
                    % Otherwise, we check to see if this is correlated with a negative event, 
                    % in which case it is a spike and we ignore it (keep previous 
                    % designation). If not, classify this trace as a
                    % weird (a.k.a. slow) fusion event because we have identified an additional fusion event
                    if isnan(DockingData.StopFrameNum)
                        OtherEventFrameNumbers = FusionData.FuseFrameNumbers;
                    else 
                        OtherEventFrameNumbers = [DockingData.StopFrameNum FusionData.FuseFrameNumbers];
                    end
                    DistanceToOtherEvents = abs(OtherEventFrameNumbers - SlowFusePosFrameNumbers(j));
                    EventsCloseBy = DistanceToOtherEvents <= RangeToFilterDifference;
                    if sum(EventsCloseBy) == 0 && ClusterSizesPos(j) > 1
                        if NumSlowFusionEventsNegDetected == 0
                            % New fusion event detected and no negative events. 
                            % Classify as weird a.k.a. slow
                            FusionData.Designation = 'Slow';
                            break
                            % We exit out of the for loop the first time this condition is 
                            % met because it doesn't matter how many other events there are 
                            % if at least one of them is isolated
                        else
                            % Need to correlate with negative events to 
                            % make sure we aren't just picking up a spike
                            DistanceToNegFusionEvents = abs(SlowFuseNegFrameNumbers - SlowFusePosFrameNumbers(j));
                            EventsCloseBy_Neg = DistanceToNegFusionEvents <= RangeToFilterDifference;
                            if sum(EventsCloseBy_Neg) == 0
                                % If the positive event is nearby a neg
                                % event already detected, and the cluster size is small
                                % enough, then assume it is fine (transient spike). Otherwise, 
                                % classify as unusual (a.k.a. "slow")
                                FusionData.Designation = 'Slow';
                                break
                                % We exit out of the for loop the first time this condition is 
                                % met because it doesn't matter how many other events there are 
                                % if at least one of them is isolated
                            end
                        end
                    end
                end
            end
         end
    end
end

end