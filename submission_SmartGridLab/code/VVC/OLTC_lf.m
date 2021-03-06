function [Tension,Courant] = OLTC_lf(Bus,Line,Noeuds_source,Param,Imax,MC,Consigne_regleur)


Indice_lignes = 1:1:size(Line,1);
Courant = zeros(size(Line(:,1),1),1);
Tension = zeros(size(Bus(:,1),1),1);


bus_test = Bus(2:end,:);
line_test = Line(4:end,:);

Sbase = Param(2);% MVA
Ubase = Param(3);


Matrice_incidence = zeros(size(bus_test,1),size(bus_test,1));
for i=1:size(line_test,1),
    Matrice_incidence(line_test(i,1),line_test(i,2)) = 1;
    Matrice_incidence(line_test(i,2),line_test(i,1)) = 1;
end

for i_depart = 1:size(Noeuds_source),
    point_depart = Noeuds_source(i_depart);
    point_etude = point_depart;

    Voisin = find(Matrice_incidence(point_depart,:)==1);
    if ~isempty(Voisin),

        for i=1:length(Voisin), 
            Liste_voisin{i,1}(1) = point_etude;
            Liste_voisin{i,1}(2) = Voisin(i);
        end

        Nb_liste_stop = 0;
        while sum(Nb_liste_stop) ~= size(Liste_voisin,1),
            Nb_voisin = length(Liste_voisin);
            cont=0;
            for i=1:Nb_voisin,
                point_etude = Liste_voisin{i,1}(end);
                Voisin = find(Matrice_incidence(point_etude,:)==1);
                Voisin = setdiff(Voisin,Liste_voisin{i,1});
                if isempty(Voisin),
                    Nb_liste_stop(i) = 1;
                    cont=cont+1;
                    Liste_voisin_1{cont,1} = [Liste_voisin{i,1}];
                end
                for j=1:length(Voisin), 
                    Nb_liste_stop(i) = 0;
                    cont=cont+1;
                    Liste_voisin_1{cont,1} = [Liste_voisin{i,1} Voisin(j)];
                end  
            end 
            Liste_voisin=Liste_voisin_1;
            clear Liste_voisin_1
        end
       

        Liste_noeuds = [];
        for i=1:size(Liste_voisin,1)
            Liste_noeuds = [Liste_noeuds Liste_voisin{i}];
        end
        Liste_noeuds = unique(Liste_noeuds);


        Bus_depart = Bus(MC(Liste_noeuds),:);
        GG = zeros(max(Bus_depart(:,1)),1);
        for i=1:length(Bus_depart(:,1)),
            GG(Bus_depart(i,1),1) = i;
        end

        Line_depart = [];Indice_courant = [];
        for i = 1:size(Line,1),
            if length(intersect([Line(i,1);Line(i,2)],Liste_noeuds)) == 2,
                Line_depart = [Line_depart;Line(i,:)];
                Indice_courant = [Indice_courant;Indice_lignes(i)];         
            end
        end
        Bus_depart(GG(point_depart),10) = 1;
        Bus_depart(GG(point_depart),2)=Consigne_regleur(i_depart);
        [bus_sol,P_loss,I_lignes_pu,iter] = lf(Line_depart,Bus_depart,Param) ;
        Tension(MC(Liste_noeuds)) = bus_sol(:,2);
        Courant(Indice_courant) = I_lignes_pu;


    %     Liste_finale_nds = [Liste_finale_nds;Liste_noeuds];
        clear Liste_voisin
    else
        Tension(MC(point_depart)) = Consigne_regleur(i_depart); % A finir
        % Mettre la bonne tension
    end
end
Tension(1) = 1;
Ibase_RD = Param(2)*10^6/(sqrt(3)*Param(1)*1000);
Imax_pu = Imax/Ibase_RD;
Courant = Courant./Imax_pu*100;