clearvars
system('taskkill /F /IM EXCEL.EXE'); clear ans
%% Parameters
global VARIABLES
VARIABLES.struct_learning = 'MCMC'; % K2 | MCMC
VARIABLES.params_learn = 'Complete'; % Complete | Missing
VARIABLES.inference_engine = @belprop_inf_engine; % global_joint_inf_engine | jtree_inf_engine | belprop_inf_engine
%% Taxonomies (labels and IDs)
Taxonomies.Naka = struct('N_yorokobi', 1, 'N_suki', 2, 'N_yasu', 3, 'N_ikari', 4, 'N_aware', 5, 'N_kowa', 6, 'N_haji', 7, 'N_iya', 8, 'N_takaburi', 9, 'N_odoroki', 10);
Taxonomies.Ekman = struct('E_anger', 11, 'E_sadness', 12, 'E_joy', 13, 'E_disgust', 14, 'E_surprise', 15, 'E_fear', 16);
%% Import Annotations
fprintf('Import Annotations.\n')
% field names: Annotations: Love/Apple -> Naka/Ekman -> workers -> annotations
Annotations.Love.Naka = ImportData('Love_Naka.csv', fieldnames(Taxonomies.Naka), 1, 3);
Annotations.Love.Ekman = IntegrateData({ ...
    ImportData('Love_Ekman_1_34.csv', fieldnames(Taxonomies.Ekman), 3, 11), ...
    ImportData('Love_Ekman_35_63.csv', fieldnames(Taxonomies.Ekman), 3, 11)}, [1,35]);
Annotations.Apple.Naka = IntegrateData({ ...
    ImportData('Apple_Naka_1_25_10workers.csv', fieldnames(Taxonomies.Naka), 3, 4), ...
    ImportData('Apple_Naka_1_25_30workers.csv', fieldnames(Taxonomies.Naka), 3, 4), ...
    ImportData('Apple_Naka_26_52_10workers.csv', fieldnames(Taxonomies.Naka), 3, 4), ...
    ImportData('Apple_Naka_26_52_30workers.csv', fieldnames(Taxonomies.Naka), 3, 4), ...
    ImportData('Apple_Naka_53_78_10workers.csv', fieldnames(Taxonomies.Naka), 3, 4), ...
    ImportData('Apple_Naka_53_78_30workers.csv', fieldnames(Taxonomies.Naka), 3, 4)}, [1, 1, 26, 26, 53, 53]);
Annotations.Apple.Ekman = IntegrateData({ ...
    ImportData('Apple_Ekman_1_25.csv', fieldnames(Taxonomies.Ekman), 3, 11), ...
    ImportData('Apple_Ekman_26_52.csv', fieldnames(Taxonomies.Ekman), 3, 11), ...
    ImportData('Apple_Ekman_53_78.csv', fieldnames(Taxonomies.Ekman), 3, 11)}, [1, 26, 53]);
%% Filter Annotations
Annotations.Love.Naka = Filter(Annotations.Love.Naka, 30);
Annotations.Love.Ekman = Filter(Annotations.Love.Ekman, 30);
Annotations.Apple.Naka = Filter(Annotations.Apple.Naka, 30);
Annotations.Apple.Ekman = Filter(Annotations.Apple.Ekman, 30);
%% Majority vote -> gold standard （重要技巧：给struct传cell array，就能得到struct array）
fprintf('Get Golds.\n')
Golds.Love = struct('Naka', GetGolds(Annotations.Love.Naka, 63), 'Ekman', GetGolds(Annotations.Love.Ekman, 63)); %length = no. sentences
Golds.Apple = struct('Naka', GetGolds(Annotations.Apple.Naka, 78), 'Ekman', GetGolds(Annotations.Apple.Ekman, 78)); %length = no. sentences
%% Bayesian network (structure and parameters) (K2 method)
fprintf('Learn Bayesian Network.\n')
BN.Love.Naka2Ekman = LearnBN(Golds.Love.Naka, Taxonomies.Naka, Annotations.Love.Ekman, Taxonomies.Ekman, 'Love_Naka2Ekman');
BN.Love.Ekman2Naka = LearnBN(Golds.Love.Ekman, Taxonomies.Ekman, Annotations.Love.Naka, Taxonomies.Naka, 'Love_Ekman2Naka');
BN.Apple.Naka2Ekman = LearnBN(Golds.Apple.Naka, Taxonomies.Naka, Annotations.Apple.Ekman, Taxonomies.Ekman, 'Apple_Naka2Ekman');
BN.Apple.Ekman2Naka = LearnBN(Golds.Apple.Ekman, Taxonomies.Ekman, Annotations.Apple.Naka, Taxonomies.Naka, 'Apple_Ekman2Naka');
%% Inference
fprintf('Inference Estimates.\n')
% field names: Estimates: Love/Apple -> Ekman/Naka -> training data -> annotations 
% (corresponding to Annotation structure: one training dataset is same as one worker)
fprintf('1: Estimates.Love.Ekman.Love_Naka2Ekman\n')
Estimates.Love.Ekman.Love_Naka2Ekman = Inference(BN.Love.Naka2Ekman.Net, Golds.Love.Naka, Taxonomies.Naka, Taxonomies.Ekman);
fprintf('2: Estimates.Love.Ekman.Apple_Naka2Ekman\n')
Estimates.Love.Ekman.Apple_Naka2Ekman = Inference(BN.Apple.Naka2Ekman.Net, Golds.Love.Naka, Taxonomies.Naka, Taxonomies.Ekman);
fprintf('3: Estimates.Love.Naka.Love_Ekman2Naka\n')
Estimates.Love.Naka.Love_Ekman2Naka = Inference(BN.Love.Ekman2Naka.Net, Golds.Love.Ekman, Taxonomies.Ekman, Taxonomies.Naka);
fprintf('4: Estimates.Love.Naka.Apple_Ekman2Naka\n')
Estimates.Love.Naka.Apple_Ekman2Naka = Inference(BN.Apple.Naka2Ekman.Net, Golds.Love.Ekman, Taxonomies.Ekman, Taxonomies.Naka);
fprintf('5: Estimates.Apple.Ekman.Love_Naka2Ekman\n')
Estimates.Apple.Ekman.Love_Naka2Ekman = Inference(BN.Love.Naka2Ekman.Net, Golds.Apple.Naka, Taxonomies.Naka, Taxonomies.Ekman);
fprintf('6: Estimates.Apple.Ekman.Apple_Naka2Ekman\n')
Estimates.Apple.Ekman.Apple_Naka2Ekman = Inference(BN.Apple.Naka2Ekman.Net, Golds.Apple.Naka, Taxonomies.Naka, Taxonomies.Ekman);
fprintf('7: Estimates.Apple.Naka.Love_Ekman2Naka\n')
Estimates.Apple.Naka.Love_Ekman2Naka = Inference(BN.Love.Ekman2Naka.Net, Golds.Apple.Ekman, Taxonomies.Ekman, Taxonomies.Naka);
fprintf('8: Estimates.Apple.Naka.Apple_Ekman2Naka\n')
Estimates.Apple.Naka.Apple_Ekman2Naka = Inference(BN.Apple.Naka2Ekman.Net, Golds.Apple.Ekman, Taxonomies.Ekman, Taxonomies.Naka);
%% Accuracy
fprintf('Compute Accuracy.\n')
Accuracies.Love_Naka2Ekman = Evaluate([Estimates.Love.Ekman.Love_Naka2Ekman, Estimates.Apple.Ekman.Love_Naka2Ekman],[Golds.Love.Ekman, Golds.Apple.Ekman]);
Accuracies.Love_Ekman2Naka = Evaluate([Estimates.Love.Naka.Love_Ekman2Naka, Estimates.Apple.Naka.Love_Ekman2Naka],[Golds.Love.Naka, Golds.Apple.Naka]);
Accuracies.Apple_Naka2Ekman = Evaluate([Estimates.Love.Ekman.Apple_Naka2Ekman, Estimates.Apple.Ekman.Apple_Naka2Ekman],[Golds.Love.Ekman, Golds.Apple.Ekman]);
Accuracies.Apple_Ekman2Naka = Evaluate([Estimates.Love.Naka.Apple_Ekman2Naka, Estimates.Apple.Naka.Apple_Ekman2Naka],[Golds.Love.Naka, Golds.Apple.Naka]);
Accuracies.Average = mean([Accuracies.Love_Naka2Ekman, Accuracies.Love_Ekman2Naka, Accuracies.Apple_Naka2Ekman, Accuracies.Apple_Ekman2Naka]);
fprintf('Finished.\n');