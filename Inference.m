function Estimates = Inference(Net, Golds, SourceTaxonomy, TargetTaxonomy)
    source_labels = fieldnames(SourceTaxonomy);
    target_labels = fieldnames(TargetTaxonomy);
    n_labels = length(source_labels) + length(target_labels);% 两个taxonomy一共有多少个label
    %要求概率的变量（P(A,B|C,D)的[A,B]）,也就是target labels（的ID的集合）
    estimated_IDs = zeros(1,length(target_labels));
    for i = 1:length(target_labels)
        estimated_IDs(i) = TargetTaxonomy.(target_labels{i});
    end
    clear i
    %inference engine
    global VARIABLES
    original_engine = VARIABLES.inference_engine(Net);
    
    %original_engine = jtree_inf_engine(Net); %不能支持所有target label集合; OK
    %original_engine = var_elim_inf_engine(Net); %OK; 不OK
    %original_engine = pearl_inf_engine(Net); %can only compute marginal on single nodes or families; 不OK
    %original_engine = belprop_inf_engine(Net); %Too many input arguments.;慢,准确
    %original_engine = stab_cond_gauss_inf_engine(Net); %Index exceeds matrix dimensions.; 不OK
    %original_engine = global_joint_inf_engine(Net); %Too many input arguments; 结果很差
    %original_engine = enumerative_inf_engine(Net);%Too many input arguments.; Undefined function 'find_mpe' for input arguments of type
    %original_engine = gaussian_inf_engine(Net); %assertion violated; Undefined function 'find_mpe' for input arguments of type
    %original_engine = cond_gauss_inf_engine(Net); %cond_gauss_inf_engine can only handle marginal queries on single nodes; Undefined function 'find_mpe' for input arguments of type
    %original_engine = quickscore_inf_engine(Net); %Not enough input arguments.; Not enough input arguments.
    %original_engine = belprop_fg_inf_engine(Net); %Reference to non-existent field 'G'.; Reference to non-existent field 'G'.
    %original_engine = likelihood_weighting_inf_engine(Net); %can't convert cell array with empty cells to matrix; Undefined function 'find_mpe' for input arguments of type
    %original_engine = gibbs_sampling_inf_engine(Net); %Undefined function or variable 'compute_posterior'.; Undefined function 'find_mpe' for input arguments of type
    
    %estimates
    target_estimates_cell = cell(length(Golds), 1);%存储返回值。（Source gold有几个，target estimate就有几个）。
    for i = 1:length(Golds) %计算每句的estimate
        %source_annotation to evidence
        evidence = Annotation2Evidence(Golds(i), n_labels, SourceTaxonomy);
        %根据evidence重新得到engine
        mpe = find_mpe(original_engine, evidence);
        target_evidence = zeros(length(target_labels), 1);
        for j = 1:length(target_labels)
            target_evidence(j) = mpe{TargetTaxonomy.(target_labels{j})};
        end
        
        %region 用边缘概率求（不合理）
%         [engine, ~] = enter_evidence(original_engine, evidence);
%         prob = marginal_nodes(engine, estimated_IDs, 1);
%         if max(prob.T(:)) == 0
%             target_evidence = ones(1,length(estimated_IDs));
%         else
%             target_evidence = ind2subv(size(prob.T), find(prob.T==max(prob.T(:)), 1)); %Awesome
%         end
        %endregion

        % test        
        if sum(target_evidence) > length(target_evidence)
           fprintf('sentence: %i, sum: %i\n', i, sum(target_evidence)); 
        end
        target_estimates_cell{i} = Evidence2Annotation(target_evidence, TargetTaxonomy);
    end
    clear i
    Estimates = CellArray2StructArray(target_estimates_cell);
end

function Target_annotation = Evidence2Annotation(Target_evidence, Target_taxonomy)
    target_labels = fieldnames(Target_taxonomy);
    for i = 1:length(Target_evidence)
        if Target_evidence(i) == 1
            Target_annotation.(target_labels{i}) = false;
        elseif Target_evidence(i) == 2
            Target_annotation.(target_labels{i}) = true;
        else
            error('Wrong evidence value: %i.', Target_evidence(i));
        end
    end
    clear i
end

function Evidence = Annotation2Evidence(Source_annotation, N_labels, Source_taxonomy)
    Evidence = cell(1,N_labels);
    labels = fieldnames(Source_taxonomy);
    for i = 1:length(labels)
        if Source_annotation.(labels{i})
            Evidence{Source_taxonomy.(labels{i})} = 2;
        else
            Evidence{Source_taxonomy.(labels{i})} = 1;
        end
    end
    clear i
end