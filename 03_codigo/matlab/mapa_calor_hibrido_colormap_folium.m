clear; clc; close all;

%% =========================================================
%  SIMULACION UIS CALIBRADA - CAMPO ELECTRICO SOBRE SATELITE
%  VERSION CORREGIDA CON MAPA HIBRIDO SIMULACION + MEDICIONES
%
%  Objetivo de esta version:
%   - Mantener el modelo de propagacion calibrado.
%   - Evitar que el mapa de calor se vea excesivamente ideal.
%   - Generar un mapa visual limitado a la zona soportada por mediciones.
%   - Corregir espacialmente la simulacion usando residuales medido-simulado.
%
%  Salidas:
%   1) mapa_calor_satelital_campo_electrico_hibrido.png
%   2) comparacion_campo_electrico_RX_calibrado.csv
%   3) metricas_error_campo_electrico_calibrado.csv
%   4) parametros_calibracion_modelo.csv
%   5) top_parametros_calibracion_modelo.csv
%% =========================================================

%% =========================================================
%  1. CONFIGURACION GENERAL DEL TRANSMISOR TX
%  =========================================================
tx.lat = 7.139785;
tx.lon = -73.117335;

tx.z_m = 1050;
tx.ant_agl_m = 10;
tx.terrain_m = tx.z_m - tx.ant_agl_m;

tx.Pt_dBm = 22.65;
tx.Ltx_dB = 1.0;

tx.Gmax_dBi = 10.0;
tx.azimuth_deg = 330;
tx.downtilt_deg = 0;

tx.hpbw_az_deg = 70;
tx.hpbw_el_deg = 65;

tx.SLAmax_dB = 25;
tx.FBR_dB = 30;
tx.minGain_dBi = -20;

%% =========================================================
%  2. CONFIGURACION GENERAL DE RECEPTORES RX
%  =========================================================
rx.ant_agl_m = 1.5;
rx.Gr_dBi = 0.0;
rx.Lrx_dB = 1.0;

rxList(1).lat = 7.140807;
rxList(1).lon = -73.117425;
rxList(1).z_m = 1017.4;
rxList(1).E_meas_dBuVm = 67.5;

rxList(2).lat = 7.141802;
rxList(2).lon = -73.118573;
rxList(2).z_m = 1015.0;
rxList(2).E_meas_dBuVm = 77.3;

rxList(3).lat = 7.140902;
rxList(3).lon = -73.119060;
rxList(3).z_m = 1014.2;
rxList(3).E_meas_dBuVm = 86.9;

rxList(4).lat = 7.139772;
rxList(4).lon = -73.118862;
rxList(4).z_m = 1013.3;
rxList(4).E_meas_dBuVm = 85.3;

rxList(5).lat = 7.139485;
rxList(5).lon = -73.120615;
rxList(5).z_m = 1013.9;
rxList(5).E_meas_dBuVm = 85.6;

rxList(6).lat = 7.140268;
rxList(6).lon = -73.120995;
rxList(6).z_m = 1014.6;
rxList(6).E_meas_dBuVm = 71.8;

rxList(7).lat = 7.141012;
rxList(7).lon = -73.119530;
rxList(7).z_m = 1021.5;
rxList(7).E_meas_dBuVm = 87.4;

rxList(8).lat = 7.141888;
rxList(8).lon = -73.119448;
rxList(8).z_m = 1020.5;
rxList(8).E_meas_dBuVm = 71.1;

nRX = numel(rxList);

for i = 1:nRX
    rxList(i).ant_agl_m = rx.ant_agl_m;
    rxList(i).terrain_m = rxList(i).z_m - rxList(i).ant_agl_m;
end

%% =========================================================
%  3. PARAMETROS DE SIMULACION
%  =========================================================
sim.freq_Hz = 101.7e6;

sim.pathLossModel = "logdistance";
sim.d0_m = 1.0;
sim.pathLossExponent_n = 2.35;

sim.useShadowing = true;
sim.shadowingSigma_dB = 2;
sim.shadowingCorrelation_m = 22;
sim.randomSeed = 17;

sim.PL_d0_measured_dB = NaN;

sim.grid_step_m = 2.0;
sim.margin_m = 140;

sim.defaultBldgH_m = 12;
sim.maxExtraLoss_dB = 8;

sim.useBuildings = true;
sim.useCampusMask = true;
sim.useVerticalPattern = true;

%% =========================================================
%  3.1 AJUSTES VISUALES DEL MAPA DE CALOR
%  =========================================================
% Opciones disponibles:
%   "hybrid"         -> simulacion corregida con residuales de medicion
%   "measured_interp"-> mapa interpolado solo desde mediciones RX
%   "simulated"      -> mapa simulado puro en toda la zona del campus
sim.visualMode = "hybrid";

% Suavizado visual moderado. Valores grandes hacen que el mapa se vea ideal.
sim.smoothSigma = 1.15;

% Malla fina para graficar sobre mapa satelital.
sim.fineGridSize = 650;

% Zona de influencia visual alrededor de puntos RX y TX.
sim.measurementInfluenceRadius_m = 72;

% Corredores de visualizacion entre TX y cada punto RX.
sim.measurementCorridorRadius_m = 52;

% Parametros IDW para correccion espacial por residuales.
sim.residualIDWPower = 2.2;
sim.residualMaxRadius_m = 190;

% Parametros IDW para mapa construido solo con mediciones.
sim.measuredIDWPower = 2.0;
sim.measuredMaxRadius_m = 170;

% Transparencia/densidad del heatmap en geoaxes.
sim.geoPointSize = 7;
sim.geoPointAlpha = 0.052;
sim.geoStride = 1;

% Ajuste de contraste. Si true, usa principalmente el rango de mediciones.
sim.colorScaleFromMeasurements = true;
sim.colorPadding_dB = 1.2;

% Permite mostrar u ocultar trayectorias TX-RX.
sim.showTxRxTrajectories = false;
sim.showReferenceRadii = false;
sim.referenceRadii_m = [25 50 75 100 150 200];

% Distancia minima numerica para no tener singularidades cerca del TX.
sim.minDisplayDistance_m = 2.0;

%% =========================================================
%  4. CALIBRACION AUTOMATICA
%  =========================================================
sim.autoCalibrate = true;

sim.calibrationRX_ids = 1:nRX;
sim.validationRX_ids = setdiff(1:nRX, sim.calibrationRX_ids);

calib.n_values = 2.0:0.05:4.0;
calib.azimuth_values = 290:2:360;
calib.maxObstacleLoss_values = [0 3 6 9 12 15];
calib.useBuildings_values = [false true];

%% =========================================================
%  5. ARCHIVOS DE ENTRADA
%  =========================================================
files.buildingsShp = fullfile("insumos_cartograficos", "Edificios UIS.shp");
files.campusBoundaryShp = fullfile("insumos_cartograficos", "Poligono UIS.shp");

%% =========================================================
%  6. CONSTANTES
%  =========================================================
f_MHz = sim.freq_Hz / 1e6;
f_GHz = sim.freq_Hz / 1e9;

PL_d0_FSPL_dB = 32.44 + 20*log10(f_MHz) + 20*log10(sim.d0_m/1000);

if isnan(sim.PL_d0_measured_dB)
    PL_d0_dB = PL_d0_FSPL_dB;
else
    PL_d0_dB = sim.PL_d0_measured_dB;
end

%% =========================================================
%  7. DEFINICION DE MALLA GEOGRAFICA
%  =========================================================
lat0 = mean([tx.lat, [rxList.lat]]);
lon0 = mean([tx.lon, [rxList.lon]]);

m_per_deg_lat = 111320;
m_per_deg_lon = 111320 * cosd(lat0);

lat_min = min([tx.lat, [rxList.lat]]) - (sim.margin_m / m_per_deg_lat);
lat_max = max([tx.lat, [rxList.lat]]) + (sim.margin_m / m_per_deg_lat);
lon_min = min([tx.lon, [rxList.lon]]) - (sim.margin_m / m_per_deg_lon);
lon_max = max([tx.lon, [rxList.lon]]) + (sim.margin_m / m_per_deg_lon);

lat_vec = lat_min : (sim.grid_step_m / m_per_deg_lat) : lat_max;
lon_vec = lon_min : (sim.grid_step_m / m_per_deg_lon) : lon_max;
[LonGrid, LatGrid] = meshgrid(lon_vec, lat_vec);

[nRows, nCols] = size(LatGrid);

%% =========================================================
%  8. TERRENO APROXIMADO
%  =========================================================
terrainLat = [tx.lat, [rxList.lat]];
terrainLon = [tx.lon, [rxList.lon]];
terrainZ = [tx.terrain_m, [rxList.terrain_m]];

try
    terrainF = scatteredInterpolant(terrainLon(:), terrainLat(:), terrainZ(:), 'natural', 'nearest');
catch
    terrainF = scatteredInterpolant(terrainLon(:), terrainLat(:), terrainZ(:), 'linear', 'nearest');
end

TerrainGrid = terrainF(LonGrid, LatGrid);
AnalysisZGrid = TerrainGrid + rx.ant_agl_m;

%% =========================================================
%  9. CARGA DE SHAPEFILES
%  =========================================================
buildings = struct('Lat', {}, 'Lon', {}, 'H', {});
campusPolys = struct('Lat', {}, 'Lon', {}, 'H', {});

if strlength(files.buildingsShp) > 0 && isfile(files.buildingsShp)
    buildings = loadPolygonShapefile(files.buildingsShp, sim.defaultBldgH_m, true);
else
    warning('No se encontro el shapefile de edificios. Se continuara sin edificios.');
    sim.useBuildings = false;
    calib.useBuildings_values = false;
    calib.maxObstacleLoss_values = 0;
end

if strlength(files.campusBoundaryShp) > 0 && isfile(files.campusBoundaryShp)
    campusPolys = loadPolygonShapefile(files.campusBoundaryShp, 0, false);
else
    warning('No se encontro el shapefile del poligono UIS. Se graficara sin mascara de campus.');
    sim.useCampusMask = false;
end

%% =========================================================
%  10. MASCARA DEL CAMPUS
%  =========================================================
insideCampus = true(size(LatGrid));

if ~isempty(campusPolys) && sim.useCampusMask
    insideCampus = false(size(LatGrid));
    for k = 1:numel(campusPolys)
        insideCampus = insideCampus | inpolygon(LonGrid, LatGrid, campusPolys(k).Lon, campusPolys(k).Lat);
    end
end

%% =========================================================
%  11. SHADOWING
%  =========================================================
Shadowing_dB_grid = generateCorrelatedShadowing(size(LatGrid), sim.shadowingSigma_dB, ...
    sim.shadowingCorrelation_m, sim.grid_step_m, sim.randomSeed, sim.useShadowing);

%% =========================================================
%  12. CALIBRACION DEL MODELO CON LOS PUNTOS RX
%  =========================================================
if sim.autoCalibrate
    fprintf('\n==================== CALIBRACION AUTOMATICA ====================\n');
    fprintf('Buscando mejor n, azimut, perdida por edificios y correccion global...\n');

    [tx, sim, correction_global_dB, TcalibBest, TcalibTop] = calibratePropagationModel( ...
        tx, rx, sim, calib, rxList, LonGrid, LatGrid, Shadowing_dB_grid, ...
        buildings, terrainF, f_MHz, f_GHz, PL_d0_dB);

    writetable(TcalibBest, 'parametros_calibracion_modelo.csv');
    writetable(TcalibTop, 'top_parametros_calibracion_modelo.csv');

    fprintf('\nParametros ajustados:\n');
    fprintf('n Log-Distance       : %.3f\n', sim.pathLossExponent_n);
    fprintf('Azimut TX            : %.2f grados\n', tx.azimuth_deg);
    fprintf('Usar edificios       : %d\n', sim.useBuildings);
    fprintf('Perdida maxima edif. : %.2f dB\n', sim.maxExtraLoss_dB);
    fprintf('Correccion global    : %.2f dB\n', correction_global_dB);
    fprintf('Archivo exportado    : parametros_calibracion_modelo.csv\n');
    fprintf('Archivo exportado    : top_parametros_calibracion_modelo.csv\n');
    fprintf('================================================================\n\n');
else
    correction_global_dB = 0;
end

%% =========================================================
%  13. CALCULO FINAL EN TODA LA MALLA
%  =========================================================
Pr_dBm = nan(size(LatGrid));
E_dBuVm = nan(size(LatGrid));
E_uVm = nan(size(LatGrid));

for r = 1:nRows
    for ccol = 1:nCols
        if ~insideCampus(r, ccol)
            continue;
        end

        p.lat = LatGrid(r, ccol);
        p.lon = LonGrid(r, ccol);
        p.terrain_m = TerrainGrid(r, ccol);
        p.ant_agl_m = rx.ant_agl_m;
        p.z_m = AnalysisZGrid(r, ccol);

        [Pr_raw, E_raw] = evaluatePoint(tx, rx, sim, p, LonGrid, LatGrid, ...
            Shadowing_dB_grid, buildings, terrainF, f_MHz, f_GHz, PL_d0_dB);

        Pr_final = Pr_raw + correction_global_dB;
        E_final = E_raw + correction_global_dB;

        Pr_dBm(r, ccol) = Pr_final;
        E_dBuVm(r, ccol) = E_final;
        E_uVm(r, ccol) = 10^(E_final/20);
    end
end

%% =========================================================
%  14. CALCULO FINAL EN RX
%  =========================================================
rxResults = struct([]);

for i = 1:nRX
    pRX.lat = rxList(i).lat;
    pRX.lon = rxList(i).lon;
    pRX.z_m = rxList(i).z_m;
    pRX.terrain_m = rxList(i).terrain_m;
    pRX.ant_agl_m = rxList(i).ant_agl_m;

    [Pr_raw, E_raw, details] = evaluatePoint(tx, rx, sim, pRX, LonGrid, LatGrid, ...
        Shadowing_dB_grid, buildings, terrainF, f_MHz, f_GHz, PL_d0_dB);

    Pr_final = Pr_raw + correction_global_dB;
    E_final = E_raw + correction_global_dB;
    E_meas = rxList(i).E_meas_dBuVm;
    Pr_meas_equiv = measuredFieldToReceivedPower_dBm(E_meas, f_MHz, rx.Gr_dBi, rx.Lrx_dB);

    if ~isnan(E_meas)
        errorE = E_final - E_meas;
        absErrorE = abs(errorE);
        residualE = E_meas - E_final;
    else
        errorE = NaN;
        absErrorE = NaN;
        residualE = NaN;
    end

    rxResults(i).rx_id = i;
    rxResults(i).lat = pRX.lat;
    rxResults(i).lon = pRX.lon;
    rxResults(i).distancia_2D_m = details.d2D_m;
    rxResults(i).distancia_3D_m = details.d3D_m;
    rxResults(i).E_medido_dBuVm = E_meas;
    rxResults(i).E_simulado_dBuVm = E_final;
    rxResults(i).E_simulado_uVm = 10^(E_final/20);
    rxResults(i).error_dB = errorE;
    rxResults(i).residual_medido_menos_simulado_dB = residualE;
    rxResults(i).error_absoluto_dB = absErrorE;
    rxResults(i).Pr_simulado_dBm = Pr_final;
    rxResults(i).Pr_medido_equiv_dBm = Pr_meas_equiv;
    rxResults(i).Gt_dBi = details.Gt_dBi;
    rxResults(i).PLbase_dB = details.PLbase_dB;
    rxResults(i).Lobs_dB = details.Lobs_dB;
    rxResults(i).Ltotal_dB = details.Ltotal_dB;
    rxResults(i).blocked = details.isBlocked;
end

%% =========================================================
%  15. METRICAS DE ERROR
%  =========================================================
E_meas_final = [rxResults.E_medido_dBuVm];
E_sim_final = [rxResults.E_simulado_dBuVm];

validMask = ~isnan(E_meas_final) & ~isnan(E_sim_final);

if any(validMask)
    err = E_sim_final(validMask) - E_meas_final(validMask);
    MAE_dB = mean(abs(err));
    RMSE_dB = sqrt(mean(err.^2));
    Bias_dB = mean(err);
    STD_error_dB = std(err);
    puntos_validos = sum(validMask);
else
    MAE_dB = NaN;
    RMSE_dB = NaN;
    Bias_dB = NaN;
    STD_error_dB = NaN;
    puntos_validos = 0;
end

%% =========================================================
%  16. IMPRESION EN COMMAND WINDOW
%  =========================================================
fprintf('\n==================== COMPARACION POR RECEPTOR ====================\n');
fprintf('Frecuencia: %.2f MHz\n', f_MHz);
fprintf('Potencia TX configurada: %.2f dBm\n', tx.Pt_dBm);
fprintf('Ganancia maxima TX: %.2f dBi\n', tx.Gmax_dBi);
fprintf('EIRP aproximada: %.2f dBm\n', tx.Pt_dBm - tx.Ltx_dB + tx.Gmax_dBi);
fprintf('n Log-Distance ajustado: %.3f\n', sim.pathLossExponent_n);
fprintf('Azimut TX ajustado: %.2f grados\n', tx.azimuth_deg);
fprintf('Usar edificios: %d\n', sim.useBuildings);
fprintf('Perdida maxima por edificios: %.2f dB\n', sim.maxExtraLoss_dB);
fprintf('Correccion global aplicada: %.2f dB\n', correction_global_dB);
fprintf('Modo visual del mapa: %s\n', sim.visualMode);
fprintf('==================================================================\n');

for i = 1:nRX
    fprintf('\n-------------------- RX %d --------------------\n', i);
    fprintf('Distancia TX-RX 2D: %.2f m\n', rxResults(i).distancia_2D_m);
    fprintf('Distancia TX-RX 3D: %.2f m\n', rxResults(i).distancia_3D_m);
    fprintf('Potencia recibida simulada: %.2f dBm\n', rxResults(i).Pr_simulado_dBm);

    if ~isnan(rxResults(i).Pr_medido_equiv_dBm)
        fprintf('Potencia recibida equivalente medida: %.2f dBm\n', rxResults(i).Pr_medido_equiv_dBm);
    else
        fprintf('Potencia recibida equivalente medida: NaN\n');
    end

    fprintf('Campo electrico simulado: %.2f dBuV/m (%.2f uV/m)\n', ...
        rxResults(i).E_simulado_dBuVm, rxResults(i).E_simulado_uVm);

    fprintf('Campo electrico medido: %.2f dBuV/m\n', rxResults(i).E_medido_dBuVm);
    fprintf('Error E sim-med: %.2f dB\n', rxResults(i).error_dB);
    fprintf('Residual E med-sim: %.2f dB\n', rxResults(i).residual_medido_menos_simulado_dB);

    fprintf('Gt efectiva: %.2f dBi | PLbase: %.2f dB | Lobs: %.2f dB | Ltotal: %.2f dB | Bloqueado: %d\n', ...
        rxResults(i).Gt_dBi, rxResults(i).PLbase_dB, rxResults(i).Lobs_dB, rxResults(i).Ltotal_dB, rxResults(i).blocked);
end

fprintf('\n==================== RESUMEN DEL MODELO ====================\n');
fprintf('Puntos validos comparados: %d\n', puntos_validos);
fprintf('MAE  : %.3f dB\n', MAE_dB);
fprintf('RMSE : %.3f dB\n', RMSE_dB);
fprintf('Bias : %.3f dB\n', Bias_dB);
fprintf('STD  : %.3f dB\n', STD_error_dB);
fprintf('===========================================================\n\n');

%% =========================================================
%  17. MAPA DE CALOR SOBRE IMAGEN SATELITAL
%      CORREGIDO PARA VERSE MENOS IDEAL Y MAS SIMILAR A MEDICIONES
%  =========================================================
[E_visual_grid, supportMaskGrid, visualLabel] = buildVisualFieldMap( ...
    E_dBuVm, LonGrid, LatGrid, tx, rxList, rxResults, sim, insideCampus);

LonFine = linspace(min(LonGrid(:)), max(LonGrid(:)), sim.fineGridSize);
LatFine = linspace(min(LatGrid(:)), max(LatGrid(:)), sim.fineGridSize);
[LonFineGrid, LatFineGrid] = meshgrid(LonFine, LatFine);

EGeoFine = interp2(LonGrid, LatGrid, E_visual_grid, LonFineGrid, LatFineGrid, 'linear');

supportMaskFine = interp2(LonGrid, LatGrid, double(supportMaskGrid), LonFineGrid, LatFineGrid, 'nearest') > 0.5;

insideCampusFine = true(size(LatFineGrid));

if ~isempty(campusPolys) && sim.useCampusMask
    insideCampusFine = false(size(LatFineGrid));
    for k = 1:numel(campusPolys)
        insideCampusFine = insideCampusFine | inpolygon( ...
            LonFineGrid, LatFineGrid, campusPolys(k).Lon, campusPolys(k).Lat);
    end
end

EGeoFine(~insideCampusFine) = NaN;

if lower(string(sim.visualMode)) ~= "simulated"
    EGeoFine(~supportMaskFine) = NaN;
end

validE = EGeoFine(~isnan(EGeoFine));

if isempty(validE)
    error('No hay valores validos de campo electrico para graficar. Revisa la mascara de medicion.');
end

if sim.colorScaleFromMeasurements && lower(string(sim.visualMode)) ~= "simulated"
    validMeasColor = [rxList.E_meas_dBuVm];
    validMeasColor = validMeasColor(~isnan(validMeasColor));

    if numel(validMeasColor) >= 2
        cminE = min(validMeasColor) - sim.colorPadding_dB;
        cmaxE = max(validMeasColor) + sim.colorPadding_dB;
    else
        cminE = prctile(validE, 5);
        cmaxE = prctile(validE, 98);
    end
else
    cminE = prctile(validE, 5);
    cmaxE = prctile(validE, 98);
end

if cmaxE <= cminE
    cminE = min(validE) - 1;
    cmaxE = max(validE) + 1;
end

hasGeoPlot = exist('geoaxes', 'file') == 2 && exist('geoscatter', 'file') == 2;

if hasGeoPlot
    figSat = figure('Name', 'Mapa satelital de campo electrico ', ...
                    'Color', 'w', ...
                    'Position', [120 80 1250 850]);

    gx = geoaxes(figSat);
    hold(gx, 'on');

    try
        geobasemap(gx, 'satellite');
    catch
        geobasemap(gx, 'streets');
    end

    try
        enableDefaultInteractivity(gx);
    catch
    end

    try
        gx.Interactions = [panInteraction zoomInteraction dataTipInteraction];
    catch
    end

    try
        axtoolbar(gx, {'pan','zoomin','zoomout','restoreview','datacursor'});
    catch
    end

    try
        pan(figSat, 'on');
        zoom(figSat, 'on');
    catch
    end

    strideMask = false(size(EGeoFine));
    strideMask(1:sim.geoStride:end, 1:sim.geoStride:end) = true;
    geoMask = ~isnan(EGeoFine) & strideMask;

    latPlot = LatFineGrid(geoMask);
    lonPlot = LonFineGrid(geoMask);
    ePlot = EGeoFine(geoMask);

    ePlot(ePlot < cminE) = cminE;
    ePlot(ePlot > cmaxE) = cmaxE;

    hHeatSoft = geoscatter(gx, latPlot, lonPlot, sim.geoPointSize*5.2, ePlot, ...
        'filled', 'o', ...
        'MarkerFaceAlpha', 0.014, ...
        'MarkerEdgeAlpha', 0.00, ...
        'DisplayName', 'Campo electrico difuso');

    hHeatMain = geoscatter(gx, latPlot, lonPlot, sim.geoPointSize, ePlot, ...
        'filled', 'o', ...
        'MarkerFaceAlpha', sim.geoPointAlpha, ...
        'MarkerEdgeAlpha', 0.00, ...
        'DisplayName', 'Campo electrico');

    try
        hHeatSoft.HitTest = 'off';
        hHeatSoft.PickableParts = 'none';
        hHeatMain.HitTest = 'off';
        hHeatMain.PickableParts = 'none';
    catch
    end

    if sim.showTxRxTrajectories
        for i = 1:nRX
            hLine = geoplot(gx, [tx.lat rxList(i).lat], [tx.lon rxList(i).lon], ...
                '-', 'LineWidth', 0.85, 'Color', [1 1 1 0.32], ...
                'DisplayName', 'Trayectoria TX-RX');
            try
                hLine.HitTest = 'off';
                hLine.PickableParts = 'none';
            catch
            end
        end
    end

    if sim.showReferenceRadii
        for rr = sim.referenceRadii_m
            [latCircle, lonCircle] = circleLatLon(tx.lat, tx.lon, rr, 240);
            hCircle = geoplot(gx, latCircle, lonCircle, 'w--', 'LineWidth', 0.65);
            try
                hCircle.HitTest = 'off';
                hCircle.PickableParts = 'none';
            catch
            end
        end
    end

    if ~isempty(campusPolys) && sim.useCampusMask
        for k = 1:numel(campusPolys)
            hCampusW = geoplot(gx, campusPolys(k).Lat, campusPolys(k).Lon, ...
                'w-', 'LineWidth', 1.8);

            hCampusK = geoplot(gx, campusPolys(k).Lat, campusPolys(k).Lon, ...
                'k-', 'LineWidth', 0.7);

            try
                hCampusW.HitTest = 'off';
                hCampusW.PickableParts = 'none';
                hCampusK.HitTest = 'off';
                hCampusK.PickableParts = 'none';
            catch
            end
        end
    end

    hTX = geoscatter(gx, tx.lat, tx.lon, 210, 'r', '^', 'filled', ...
        'MarkerEdgeColor', 'w', ...
        'LineWidth', 1.4, ...
        'DisplayName', 'Transmisor TX');

    try
        hTX.DataTipTemplate.DataTipRows = [
            dataTipTextRow('Antena', {'TX'})
            dataTipTextRow('Latitud', tx.lat)
            dataTipTextRow('Longitud', tx.lon)
            dataTipTextRow('Altura total [m]', tx.z_m)
            dataTipTextRow('Altura antena AGL [m]', tx.ant_agl_m)
            dataTipTextRow('Terreno [m]', tx.terrain_m)
            dataTipTextRow('Potencia TX [dBm]', tx.Pt_dBm)
            dataTipTextRow('Perdida TX [dB]', tx.Ltx_dB)
            dataTipTextRow('Frecuencia [MHz]', f_MHz)
            dataTipTextRow('Ganancia max [dBi]', tx.Gmax_dBi)
            dataTipTextRow('Azimut ajustado [deg]', tx.azimuth_deg)
            dataTipTextRow('Downtilt [deg]', tx.downtilt_deg)
            dataTipTextRow('HPBW azimutal [deg]', tx.hpbw_az_deg)
            dataTipTextRow('HPBW elevacion [deg]', tx.hpbw_el_deg)
            dataTipTextRow('n ajustado', sim.pathLossExponent_n)
            dataTipTextRow('Correccion global [dB]', correction_global_dB)
            dataTipTextRow('Modo visual', {char(sim.visualMode)})
        ];

        hTX.DataTipTemplate.Interpreter = 'none';
    catch ME
        warning('No se pudieron configurar los Data Tips de TX: %s', ME.message);
    end

    rx_id_tip       = [rxResults.rx_id]';
    rx_lat_tip      = [rxResults.lat]';
    rx_lon_tip      = [rxResults.lon]';
    rx_z_tip        = [rxList.z_m]';
    rx_ant_tip      = [rxList.ant_agl_m]';
    rx_terrain_tip  = [rxList.terrain_m]';
    rx_dist_tip     = [rxResults.distancia_2D_m]';
    rx_Emeas_tip    = [rxResults.E_medido_dBuVm]';
    rx_Esim_tip     = [rxResults.E_simulado_dBuVm]';
    rx_Error_tip    = [rxResults.error_dB]';
    rx_Residual_tip = [rxResults.residual_medido_menos_simulado_dB]';
    rx_EuVm_tip     = [rxResults.E_simulado_uVm]';
    rx_PrSim_tip    = [rxResults.Pr_simulado_dBm]';

    hRX = geoscatter(gx, rx_lat_tip, rx_lon_tip, 105, 'w', 'o', 'filled', ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.2, ...
        'DisplayName', 'Receptores RX');

    try
        hRX.DataTipTemplate.DataTipRows = [
            dataTipTextRow('RX', rx_id_tip)
            dataTipTextRow('Latitud', rx_lat_tip)
            dataTipTextRow('Longitud', rx_lon_tip)
            dataTipTextRow('Altura total RX [m]', rx_z_tip)
            dataTipTextRow('Altura antena RX AGL [m]', rx_ant_tip)
            dataTipTextRow('Terreno RX [m]', rx_terrain_tip)
            dataTipTextRow('Distancia TX-RX [m]', rx_dist_tip)
            dataTipTextRow('E medido [dBuV/m]', rx_Emeas_tip)
            dataTipTextRow('E simulado [dBuV/m]', rx_Esim_tip)
            dataTipTextRow('Error sim-med [dB]', rx_Error_tip)
            dataTipTextRow('Residual med-sim [dB]', rx_Residual_tip)
            dataTipTextRow('E simulado [uV/m]', rx_EuVm_tip)
            dataTipTextRow('Pr simulado [dBm]', rx_PrSim_tip)
        ];

        hRX.DataTipTemplate.Interpreter = 'none';
    catch ME
        warning('No se pudieron configurar los Data Tips de RX: %s', ME.message);
    end

    for i = 1:nRX
        try
            text(gx, rx_lat_tip(i), rx_lon_tip(i), sprintf(' P%d', rx_id_tip(i)), ...
                'Color', 'w', 'FontWeight', 'bold', 'FontSize', 8, ...
                'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
        catch
        end
    end

    try
        dcm = datacursormode(figSat);
        dcm.Enable = 'off';
    catch
    end

    allLat = [tx.lat; [rxList.lat]'];
    allLon = [tx.lon; [rxList.lon]'];

    if ~isempty(campusPolys) && sim.useCampusMask
        for k = 1:numel(campusPolys)
            latCampus = campusPolys(k).Lat;
            lonCampus = campusPolys(k).Lon;

            latCampus = latCampus(~isnan(latCampus));
            lonCampus = lonCampus(~isnan(lonCampus));

            allLat = [allLat; latCampus(:)];
            allLon = [allLon; lonCampus(:)];
        end
    end

    latPad = 0.00015;
    lonPad = 0.00015;

    geolimits(gx, ...
        [min(allLat)-latPad, max(allLat)+latPad], ...
        [min(allLon)-lonPad, max(allLon)+lonPad]);

    try
        colormap(gx, measuredLikeColormap(256));
    catch
        colormap(gx, turbo);
    end

    try
        clim(gx, [cminE cmaxE]);
    catch
        caxis(gx, [cminE cmaxE]);
    end

    cb = colorbar;
    ylabel(cb, 'Magnitud medida / interpolada (dB\muV/m)', 'FontWeight', 'bold');

    title(gx, sprintf('Mapa satelital del campo electrico - %s - %.1f MHz', visualLabel, f_MHz), ...
        'FontWeight', 'bold');

    try
        legend(gx, [hTX hRX], {'TX', 'RX'}, 'Location', 'best');
    catch
    end

    try
        exportgraphics(figSat, 'mapa_calor_satelital.png', 'Resolution', 300);
        disp('Archivo exportado: mapa_calor_satelital_campo_electrico_hibrido.png');
    catch ME
        warning('No se pudo exportar el mapa satelital: %s', ME.message);
    end
else
    warning('Tu version de MATLAB no tiene geoaxes/geoscatter. No se genero mapa satelital.');
end

%% =========================================================
%  18. EXPORTACION DE CSV
%  =========================================================
Tcomp = table( ...
    [rxResults.rx_id]', ...
    [rxResults.lat]', ...
    [rxResults.lon]', ...
    [rxResults.distancia_2D_m]', ...
    [rxResults.distancia_3D_m]', ...
    [rxResults.E_medido_dBuVm]', ...
    [rxResults.E_simulado_dBuVm]', ...
    [rxResults.error_dB]', ...
    [rxResults.residual_medido_menos_simulado_dB]', ...
    [rxResults.error_absoluto_dB]', ...
    [rxResults.Pr_medido_equiv_dBm]', ...
    [rxResults.Pr_simulado_dBm]', ...
    [rxResults.Gt_dBi]', ...
    [rxResults.PLbase_dB]', ...
    [rxResults.Lobs_dB]', ...
    [rxResults.Ltotal_dB]', ...
    [rxResults.blocked]', ...
    'VariableNames', { ...
    'rx_id', ...
    'lat', ...
    'lon', ...
    'distancia_2D_m', ...
    'distancia_3D_m', ...
    'E_medido_dBuVm', ...
    'E_simulado_dBuVm', ...
    'error_sim_menos_medido_dB', ...
    'residual_medido_menos_simulado_dB', ...
    'error_absoluto_dB', ...
    'Pr_medido_equiv_dBm', ...
    'Pr_simulado_dBm', ...
    'Gt_dBi', ...
    'PLbase_dB', ...
    'Lobs_dB', ...
    'Ltotal_dB', ...
    'blocked'});

writetable(Tcomp, 'comparacion_campo_electrico_RX_calibrado.csv');
disp('Archivo exportado: comparacion_campo_electrico_RX_calibrado.csv');

Tmetrics = table( ...
    puntos_validos, ...
    MAE_dB, ...
    RMSE_dB, ...
    Bias_dB, ...
    STD_error_dB, ...
    correction_global_dB, ...
    sim.pathLossExponent_n, ...
    sim.shadowingSigma_dB, ...
    sim.maxExtraLoss_dB, ...
    tx.azimuth_deg, ...
    sim.useBuildings, ...
    f_MHz, ...
    string(sim.visualMode), ...
    sim.measurementInfluenceRadius_m, ...
    sim.measurementCorridorRadius_m, ...
    sim.residualIDWPower, ...
    sim.residualMaxRadius_m, ...
    'VariableNames', { ...
    'puntos_validos', ...
    'MAE_dB', ...
    'RMSE_dB', ...
    'Bias_dB', ...
    'STD_error_dB', ...
    'correccion_global_dB', ...
    'n_logdistance', ...
    'sigma_shadowing_dB', ...
    'maxExtraLoss_dB', ...
    'azimut_TX_deg', ...
    'useBuildings', ...
    'frecuencia_MHz', ...
    'visualMode', ...
    'measurementInfluenceRadius_m', ...
    'measurementCorridorRadius_m', ...
    'residualIDWPower', ...
    'residualMaxRadius_m'});

writetable(Tmetrics, 'metricas_error_campo_electrico_calibrado.csv');
disp('Archivo exportado: metricas_error_campo_electrico_calibrado.csv');

%% =========================================================
%  19. FUNCIONES AUXILIARES
%  =========================================================

function [Evisual, supportMask, visualLabel] = buildVisualFieldMap( ...
    EsimGrid, LonGrid, LatGrid, tx, rxList, rxResults, sim, insideCampus)

modeName = lower(string(sim.visualMode));

supportMask = buildMeasurementSupportMask( ...
    LatGrid, LonGrid, tx, rxList, ...
    sim.measurementInfluenceRadius_m, ...
    sim.measurementCorridorRadius_m, ...
    insideCampus);

rxLat = [rxList.lat]';
rxLon = [rxList.lon]';
Emeas = [rxList.E_meas_dBuVm]';
EsimRX = [rxResults.E_simulado_dBuVm]';

validMeas = ~isnan(rxLat) & ~isnan(rxLon) & ~isnan(Emeas);
validResidual = validMeas & ~isnan(EsimRX);

switch modeName
    case "simulated"
        Evisual = EsimGrid;
        Evisual(~insideCampus) = NaN;
        Evisual = smoothGrid2DNaN(Evisual, sim.smoothSigma);
        visualLabel = 'simulado calibrado';

    case "measured_interp"
        if sum(validMeas) < 3
            warning('Hay menos de 3 puntos medidos validos. Se usara el mapa simulado.');
            Evisual = EsimGrid;
            visualLabel = 'simulado por falta de mediciones';
        else
            Evisual = idwInterpolateGeoGrid( ...
                LonGrid, LatGrid, ...
                rxLat(validMeas), rxLon(validMeas), Emeas(validMeas), ...
                tx.lat, tx.lon, ...
                sim.measuredIDWPower, sim.measuredMaxRadius_m);
            visualLabel = 'interpolado desde mediciones';
        end

        Evisual(~supportMask) = NaN;
        Evisual = smoothGrid2DNaN(Evisual, sim.smoothSigma);
        Evisual(~supportMask) = NaN;

    otherwise
        if sum(validResidual) < 3
            warning('Hay menos de 3 residuales validos. Se usara mapa simulado limitado a zona de medicion.');
            Evisual = EsimGrid;
            visualLabel = 'simulado limitado';
        else
            residual = Emeas(validResidual) - EsimRX(validResidual);

            residualInterp = idwInterpolateGeoGrid( ...
                LonGrid, LatGrid, ...
                rxLat(validResidual), rxLon(validResidual), residual, ...
                tx.lat, tx.lon, ...
                sim.residualIDWPower, sim.residualMaxRadius_m);

            residualInterp(isnan(residualInterp)) = 0;

            Evisual = EsimGrid + residualInterp;
            visualLabel = 'simulado con interferencia en:';
        end

        Evisual(~supportMask) = NaN;
        Evisual = smoothGrid2DNaN(Evisual, sim.smoothSigma);
        Evisual(~supportMask) = NaN;
end
end

function supportMask = buildMeasurementSupportMask( ...
    LatGrid, LonGrid, tx, rxList, influenceRadius_m, corridorRadius_m, insideCampus)

[Xg, Yg] = latlonGridToLocalMeters(tx.lat, tx.lon, LatGrid, LonGrid);

anchorLat = [tx.lat, [rxList.lat]];
anchorLon = [tx.lon, [rxList.lon]];

anchorX = zeros(size(anchorLat));
anchorY = zeros(size(anchorLat));

for i = 1:numel(anchorLat)
    [anchorX(i), anchorY(i)] = latlonToLocalMeters(tx.lat, tx.lon, anchorLat(i), anchorLon(i));
end

minDist = inf(size(Xg));

for i = 1:numel(anchorX)
    d = hypot(Xg - anchorX(i), Yg - anchorY(i));
    minDist = min(minDist, d);
end

maskAnchors = minDist <= influenceRadius_m;
maskCorridors = false(size(Xg));

xTX = 0;
yTX = 0;

for i = 1:numel(rxList)
    [xRX, yRX] = latlonToLocalMeters(tx.lat, tx.lon, rxList(i).lat, rxList(i).lon);
    dSeg = distancePointToSegment2D(Xg, Yg, xTX, yTX, xRX, yRX);
    maskCorridors = maskCorridors | (dSeg <= corridorRadius_m);
end

supportMask = (maskAnchors | maskCorridors) & insideCampus;
end

function Z = idwInterpolateGeoGrid(LonGrid, LatGrid, latPts, lonPts, valPts, latRef, lonRef, powerIDW, maxRadius_m)
latPts = latPts(:);
lonPts = lonPts(:);
valPts = valPts(:);

valid = ~isnan(latPts) & ~isnan(lonPts) & ~isnan(valPts);
latPts = latPts(valid);
lonPts = lonPts(valid);
valPts = valPts(valid);

Z = nan(size(LonGrid));

if isempty(valPts)
    return;
end

[Xg, Yg] = latlonGridToLocalMeters(latRef, lonRef, LatGrid, LonGrid);

num = zeros(size(LonGrid));
den = zeros(size(LonGrid));
exactMaskGlobal = false(size(LonGrid));

for i = 1:numel(valPts)
    [xp, yp] = latlonToLocalMeters(latRef, lonRef, latPts(i), lonPts(i));
    d = hypot(Xg - xp, Yg - yp);

    exactMask = d < 0.35;
    exactMaskGlobal = exactMaskGlobal | exactMask;

    w = 1 ./ (max(d, 0.8) .^ powerIDW);

    if maxRadius_m > 0
        w(d > maxRadius_m) = 0;
    end

    num = num + w * valPts(i);
    den = den + w;
end

validInterp = den > 0;
Z(validInterp) = num(validInterp) ./ den(validInterp);

for i = 1:numel(valPts)
    [xp, yp] = latlonToLocalMeters(latRef, lonRef, latPts(i), lonPts(i));
    d = hypot(Xg - xp, Yg - yp);
    Z(d < 0.35) = valPts(i);
end

Z(~exactMaskGlobal & ~validInterp) = NaN;
end

function D = distancePointToSegment2D(X, Y, x1, y1, x2, y2)
vx = x2 - x1;
vy = y2 - y1;
wx = X - x1;
wy = Y - y1;

c2 = vx^2 + vy^2;

if c2 <= eps
    D = hypot(X - x1, Y - y1);
    return;
end

t = (wx .* vx + wy .* vy) ./ c2;
t = max(0, min(1, t));

projX = x1 + t .* vx;
projY = y1 + t .* vy;

D = hypot(X - projX, Y - projY);
end

function [Xg, Yg] = latlonGridToLocalMeters(latRef, lonRef, LatGrid, LonGrid)
m_per_deg_lat = 111320;
m_per_deg_lon = 111320 * cosd(latRef);

Xg = (LonGrid - lonRef) .* m_per_deg_lon;
Yg = (LatGrid - latRef) .* m_per_deg_lat;
end

function cmap = measuredLikeColormap(n)
if nargin < 1
    n = 256;
end

% =========================================================
% PALETA PERSONALIZADA TIPO FOLIUM / BRANCA
% Equivalente a:
% ['#313695','#4575b4','#74add1','#abd9e9','#ffffbf',
%  '#fdae61','#f46d43','#d73027','#a50026']
%
% Azul oscuro -> azul -> celeste -> amarillo -> naranja -> rojo
% =========================================================

hexColors = {
    '#313695'
    '#4575b4'
    '#74add1'
    '#abd9e9'
    '#ffffbf'
    '#fdae61'
    '#f46d43'
    '#d73027'
    '#a50026'
};

base = zeros(numel(hexColors), 3);

for i = 1:numel(hexColors)
    h = hexColors{i};

    if h(1) == '#'
        h = h(2:end);
    end

    base(i, :) = [
        hex2dec(h(1:2)), ...
        hex2dec(h(3:4)), ...
        hex2dec(h(5:6))
    ] / 255;
end

% Distribucion equivalente a un LinearColormap continuo.
% Si quieres una transicion uniforme entre todos los colores, deja esto asi.
xBase = linspace(0, 1, size(base, 1));

% Si quieres forzar una distribucion mas parecida al gradient_heatmap de Folium,
% puedes comentar la linea anterior y activar esta:
% xBase = [0.00 0.12 0.28 0.42 0.55 0.70 0.82 0.92 1.00];

xq = linspace(0, 1, n);

cmap = zeros(n, 3);

for k = 1:3
    cmap(:, k) = interp1(xBase, base(:, k), xq, 'linear');
end

cmap = max(0, min(1, cmap));
end

function [latCircle, lonCircle] = circleLatLon(lat0, lon0, radius_m, nPts)
if nargin < 4
    nPts = 180;
end

ang = linspace(0, 2*pi, nPts);
m_per_deg_lat = 111320;
m_per_deg_lon = 111320 * cosd(lat0);

latCircle = lat0 + (radius_m * sin(ang)) / m_per_deg_lat;
lonCircle = lon0 + (radius_m * cos(ang)) / m_per_deg_lon;
end

function [txBest, simBest, correctionBest, Tbest, Ttop] = calibratePropagationModel( ...
    tx, rx, sim, calib, rxList, LonGrid, LatGrid, Shadowing_dB_grid, ...
    buildings, terrainF, f_MHz, f_GHz, PL_d0_dB)

E_meas_all = [rxList.E_meas_dBuVm];

calIDs = sim.calibrationRX_ids(:)';
valIDs = sim.validationRX_ids(:)';

calIDs = calIDs(calIDs >= 1 & calIDs <= numel(rxList));
valIDs = valIDs(valIDs >= 1 & valIDs <= numel(rxList));

if isempty(calIDs)
    calIDs = 1:numel(rxList);
end

rows = [];
idx = 0;
totalComb = numel(calib.useBuildings_values) * numel(calib.n_values) * numel(calib.azimuth_values) * numel(calib.maxObstacleLoss_values);
comb = 0;

for ub = 1:numel(calib.useBuildings_values)
    useB = calib.useBuildings_values(ub);

    for nn = 1:numel(calib.n_values)
        nTry = calib.n_values(nn);

        for aa = 1:numel(calib.azimuth_values)
            azTry = calib.azimuth_values(aa);

            for ll = 1:numel(calib.maxObstacleLoss_values)
                maxLossTry = calib.maxObstacleLoss_values(ll);
                comb = comb + 1;

                if mod(comb, 500) == 0 || comb == totalComb
                    fprintf('Calibracion: %d / %d combinaciones evaluadas...\n', comb, totalComb);
                end

                txTry = tx;
                simTry = sim;

                txTry.azimuth_deg = azTry;
                simTry.pathLossExponent_n = nTry;
                simTry.maxExtraLoss_dB = maxLossTry;
                simTry.useBuildings = logical(useB);

                [~, E_raw_all] = evaluateRxVector(txTry, rx, simTry, rxList, ...
                    LonGrid, LatGrid, Shadowing_dB_grid, buildings, terrainF, ...
                    f_MHz, f_GHz, PL_d0_dB);

                validCal = calIDs(~isnan(E_meas_all(calIDs)) & ~isnan(E_raw_all(calIDs)));

                if isempty(validCal)
                    continue;
                end

                correctionTry = mean(E_meas_all(validCal) - E_raw_all(validCal));
                E_corr_all = E_raw_all + correctionTry;

                [maeCal, rmseCal, biasCal, stdCal, nCal] = computeErrorMetrics(E_meas_all(calIDs), E_corr_all(calIDs));

                if isempty(valIDs)
                    maeVal = NaN;
                    rmseVal = NaN;
                    biasVal = NaN;
                    stdVal = NaN;
                    nVal = 0;
                else
                    [maeVal, rmseVal, biasVal, stdVal, nVal] = computeErrorMetrics(E_meas_all(valIDs), E_corr_all(valIDs));
                end

                [maeAll, rmseAll, biasAll, stdAll, nAll] = computeErrorMetrics(E_meas_all, E_corr_all);

                idx = idx + 1;

                rows(idx).n_logdistance = nTry;
                rows(idx).azimut_TX_deg = azTry;
                rows(idx).useBuildings = logical(useB);
                rows(idx).maxExtraLoss_dB = maxLossTry;
                rows(idx).correccion_global_dB = correctionTry;
                rows(idx).MAE_cal_dB = maeCal;
                rows(idx).RMSE_cal_dB = rmseCal;
                rows(idx).Bias_cal_dB = biasCal;
                rows(idx).STD_cal_dB = stdCal;
                rows(idx).N_cal = nCal;
                rows(idx).MAE_val_dB = maeVal;
                rows(idx).RMSE_val_dB = rmseVal;
                rows(idx).Bias_val_dB = biasVal;
                rows(idx).STD_val_dB = stdVal;
                rows(idx).N_val = nVal;
                rows(idx).MAE_all_dB = maeAll;
                rows(idx).RMSE_all_dB = rmseAll;
                rows(idx).Bias_all_dB = biasAll;
                rows(idx).STD_all_dB = stdAll;
                rows(idx).N_all = nAll;
            end
        end
    end
end

if isempty(rows)
    warning('No fue posible calibrar el modelo. Se usaran parametros originales.');
    txBest = tx;
    simBest = sim;
    correctionBest = 0;

    Tbest = table(sim.pathLossExponent_n, tx.azimuth_deg, sim.useBuildings, sim.maxExtraLoss_dB, 0, ...
        'VariableNames', {'n_logdistance','azimut_TX_deg','useBuildings','maxExtraLoss_dB','correccion_global_dB'});

    Ttop = Tbest;
    return;
end

Tall = struct2table(rows);

if any(Tall.N_val > 0 & ~isnan(Tall.RMSE_val_dB))
    score = Tall.RMSE_val_dB;
else
    score = Tall.RMSE_all_dB;
end

score(isnan(score)) = inf;
[~, bestIdx] = min(score);

Tsorted = sortrows(Tall, {'RMSE_all_dB', 'MAE_all_dB'}, {'ascend', 'ascend'});
nTop = min(20, height(Tsorted));
Ttop = Tsorted(1:nTop, :);

Tbest = Tall(bestIdx, :);

txBest = tx;
simBest = sim;

txBest.azimuth_deg = Tbest.azimut_TX_deg(1);
simBest.pathLossExponent_n = Tbest.n_logdistance(1);
simBest.useBuildings = logical(Tbest.useBuildings(1));
simBest.maxExtraLoss_dB = Tbest.maxExtraLoss_dB(1);

correctionBest = Tbest.correccion_global_dB(1);
end

function [PrVec, EVec, detailsVec] = evaluateRxVector(tx, rx, sim, rxList, ...
    LonGrid, LatGrid, Shadowing_dB_grid, buildings, terrainF, f_MHz, f_GHz, PL_d0_dB)

nRX = numel(rxList);

PrVec = nan(1, nRX);
EVec = nan(1, nRX);

detailsVec = repmat(struct( ...
    'd2D_m', NaN, ...
    'd3D_m', NaN, ...
    'az_deg', NaN, ...
    'deltaAz_deg', NaN, ...
    'el_deg', NaN, ...
    'deltaEl_deg', NaN, ...
    'Gt_dBi', NaN, ...
    'PLbase_dB', NaN, ...
    'Lobs_dB', NaN, ...
    'Ltotal_dB', NaN, ...
    'isBlocked', false), 1, nRX);

for i = 1:nRX
    pRX.lat = rxList(i).lat;
    pRX.lon = rxList(i).lon;
    pRX.z_m = rxList(i).z_m;
    pRX.terrain_m = rxList(i).terrain_m;
    pRX.ant_agl_m = rxList(i).ant_agl_m;

    [PrTemp, ETemp, detailsTemp] = evaluatePoint(tx, rx, sim, pRX, ...
        LonGrid, LatGrid, Shadowing_dB_grid, buildings, terrainF, ...
        f_MHz, f_GHz, PL_d0_dB);

    PrVec(i) = PrTemp;
    EVec(i) = ETemp;

    detailsVec(i).d2D_m = getStructFieldSafe(detailsTemp, 'd2D_m', NaN);
    detailsVec(i).d3D_m = getStructFieldSafe(detailsTemp, 'd3D_m', NaN);
    detailsVec(i).az_deg = getStructFieldSafe(detailsTemp, 'az_deg', NaN);
    detailsVec(i).deltaAz_deg = getStructFieldSafe(detailsTemp, 'deltaAz_deg', NaN);
    detailsVec(i).el_deg = getStructFieldSafe(detailsTemp, 'el_deg', NaN);
    detailsVec(i).deltaEl_deg = getStructFieldSafe(detailsTemp, 'deltaEl_deg', NaN);
    detailsVec(i).Gt_dBi = getStructFieldSafe(detailsTemp, 'Gt_dBi', NaN);
    detailsVec(i).PLbase_dB = getStructFieldSafe(detailsTemp, 'PLbase_dB', NaN);
    detailsVec(i).Lobs_dB = getStructFieldSafe(detailsTemp, 'Lobs_dB', NaN);
    detailsVec(i).Ltotal_dB = getStructFieldSafe(detailsTemp, 'Ltotal_dB', NaN);
    detailsVec(i).isBlocked = getStructFieldSafe(detailsTemp, 'isBlocked', false);
end
end

function value = getStructFieldSafe(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function [MAE_dB, RMSE_dB, Bias_dB, STD_dB, N] = computeErrorMetrics(yMeas, ySim)
valid = ~isnan(yMeas) & ~isnan(ySim);
N = sum(valid);

if N == 0
    MAE_dB = NaN;
    RMSE_dB = NaN;
    Bias_dB = NaN;
    STD_dB = NaN;
    return;
end

err = ySim(valid) - yMeas(valid);

MAE_dB = mean(abs(err));
RMSE_dB = sqrt(mean(err.^2));
Bias_dB = mean(err);

if N > 1
    STD_dB = std(err);
else
    STD_dB = 0;
end
end

function [Pr_dBm, E_dBuVm, details] = evaluatePoint(tx, rx, sim, p, LonGrid, LatGrid, ...
    Shadowing_dB_grid, buildings, terrainF, f_MHz, f_GHz, PL_d0_dB)

[dx_m, dy_m] = latlonToLocalMeters(tx.lat, tx.lon, p.lat, p.lon);

d2D_m = hypot(dx_m, dy_m);
dEff_m = max(d2D_m, sim.minDisplayDistance_m);
d3D_m = sqrt(dEff_m^2 + (tx.z_m - p.z_m)^2);

az_deg = mod(atan2d(dx_m, dy_m), 360);
deltaAz_deg = wrapTo180_local(az_deg - tx.azimuth_deg);

el_deg = atan2d((p.z_m - tx.z_m), max(dEff_m, 1e-6));
deltaEl_deg = el_deg - (-tx.downtilt_deg);

if sim.useVerticalPattern
    Gt_dBi = directionalGain3D(tx, deltaAz_deg, deltaEl_deg);
else
    Gt_dBi = directionalGainAzOnly(tx, deltaAz_deg);
end

if sim.useShadowing
    Xshadow_dB = interp2(LonGrid, LatGrid, Shadowing_dB_grid, p.lon, p.lat, 'linear', 0);
else
    Xshadow_dB = 0;
end

PLbase_dB = basePathLoss_dB(sim, d3D_m, f_MHz, PL_d0_dB, Xshadow_dB);

if sim.useBuildings
    [Lobs_dB, isBlocked] = obstacleLoss(tx, p, buildings, terrainF, f_GHz, sim.maxExtraLoss_dB);
else
    Lobs_dB = 0;
    isBlocked = false;
end

Ltotal_dB = PLbase_dB + Lobs_dB;

Pr_dBm = tx.Pt_dBm + Gt_dBi - tx.Ltx_dB + rx.Gr_dBi - rx.Lrx_dB - Ltotal_dB;

E_dBuVm = receivedPowerToField_dBuVm(Pr_dBm, f_MHz, rx.Gr_dBi, rx.Lrx_dB);

details.d2D_m = d2D_m;
details.d3D_m = d3D_m;
details.az_deg = az_deg;
details.deltaAz_deg = deltaAz_deg;
details.el_deg = el_deg;
details.deltaEl_deg = deltaEl_deg;
details.Gt_dBi = Gt_dBi;
details.PLbase_dB = PLbase_dB;
details.Lobs_dB = Lobs_dB;
details.Ltotal_dB = Ltotal_dB;
details.isBlocked = isBlocked;
end

function PL_dB = basePathLoss_dB(sim, d_m, f_MHz, PL_d0_dB, Xshadow_dB)
d_m = max(d_m, sim.d0_m);
modelName = lower(string(sim.pathLossModel));

if modelName == "logdistance"
    PL_dB = PL_d0_dB + 10*sim.pathLossExponent_n*log10(d_m/sim.d0_m) + Xshadow_dB;
else
    PL_dB = 32.44 + 20*log10(f_MHz) + 20*log10(d_m/1000);
end
end

function Xshadow = generateCorrelatedShadowing(gridSize, sigma_dB, corr_m, gridStep_m, randomSeed, useShadowing)
if ~useShadowing || sigma_dB <= 0
    Xshadow = zeros(gridSize);
    return;
end

rng(randomSeed);

X = randn(gridSize);

sigmaCells = max(corr_m / max(gridStep_m, 0.1), 0.5);
X = smoothGrid2DNaN(X, sigmaCells);

validX = X(~isnan(X));

if isempty(validX)
    Xshadow = zeros(gridSize);
    return;
end

X = X - mean(validX);
stdX = std(validX);

if stdX > 0
    X = X / stdX;
end

Xshadow = sigma_dB * X;
end

function E_dBuVm = receivedPowerToField_dBuVm(Pr_dBm, f_MHz, Gr_dBi, Lrx_dB)
E_dBuVm = Pr_dBm + Lrx_dB - Gr_dBi + 20*log10(f_MHz) + 77.2;
end

function Pr_dBm = measuredFieldToReceivedPower_dBm(E_dBuVm, f_MHz, Gr_dBi, Lrx_dB)
if isnan(E_dBuVm)
    Pr_dBm = NaN;
    return;
end

Pr_dBm = E_dBuVm - Lrx_dB + Gr_dBi - 20*log10(f_MHz) - 77.2;
end

function [dx_m, dy_m] = latlonToLocalMeters(lat0, lon0, lat, lon)
m_per_deg_lat = 111320;
m_per_deg_lon = 111320 * cosd(lat0);

dx_m = (lon - lon0) .* m_per_deg_lon;
dy_m = (lat - lat0) .* m_per_deg_lat;
end

function ang180 = wrapTo180_local(ang)
ang180 = mod(ang + 180, 360) - 180;
end

function G = directionalGain3D(tx, deltaAz_deg, deltaEl_deg)
Aaz = min(12 * (deltaAz_deg ./ tx.hpbw_az_deg).^2, tx.FBR_dB);
Ael = min(12 * (deltaEl_deg ./ tx.hpbw_el_deg).^2, tx.SLAmax_dB);

Atot = min(Aaz + Ael, max(tx.FBR_dB, tx.SLAmax_dB));

G = tx.Gmax_dBi - Atot;
G = max(G, tx.minGain_dBi);
end

function G = directionalGainAzOnly(tx, deltaAz_deg)
Aaz = min(12 * (deltaAz_deg ./ tx.hpbw_az_deg).^2, tx.FBR_dB);

G = tx.Gmax_dBi - Aaz;
G = max(G, tx.minGain_dBi);
end

function [Lobs_dB, isBlocked] = obstacleLoss(tx, p, buildings, terrainF, f_GHz, maxExtraLoss_dB)
if isempty(buildings) || maxExtraLoss_dB <= 0
    Lobs_dB = 0;
    isBlocked = false;
    return;
end

[dx_m, dy_m] = latlonToLocalMeters(tx.lat, tx.lon, p.lat, p.lon);
d2D_m = hypot(dx_m, dy_m);

if d2D_m < 2
    Lobs_dB = 0;
    isBlocked = false;
    return;
end

nSamp = max(30, min(180, round(d2D_m / 1.5)));
t = linspace(0, 1, nSamp);

latLine = tx.lat + t * (p.lat - tx.lat);
lonLine = tx.lon + t * (p.lon - tx.lon);
zLine = tx.z_m + t * (p.z_m - tx.z_m);

terrainLine = terrainF(lonLine(:), latLine(:));
terrainLine = terrainLine(:)';

terrainLine(isnan(terrainLine)) = p.terrain_m;

blockedCount = 0;
maxExcess = 0;
fracBlockedTotal = 0;

for k = 1:numel(buildings)
    lonPoly = buildings(k).Lon;
    latPoly = buildings(k).Lat;
    hB = buildings(k).H;

    if isempty(lonPoly) || isempty(latPoly) || hB <= 0
        continue;
    end

    in = inpolygon(lonLine, latLine, lonPoly, latPoly);

    if any(in)
        roofAbs = terrainLine(in) + hB;
        zInside = zLine(in);
        excessVec = roofAbs - zInside;
        excess = max(excessVec);

        if excess > 0
            blockedCount = blockedCount + 1;
            maxExcess = max(maxExcess, excess);
            fracBlockedTotal = fracBlockedTotal + sum(in) / nSamp;
        end
    end
end

isBlocked = blockedCount > 0;

if ~isBlocked
    Lobs_dB = 0;
    return;
end

Lobs_dB = 4 + 4*log10(1 + max(f_GHz, 0.05)) + ...
          8*log10(1 + maxExcess) + ...
          10*fracBlockedTotal + ...
          2*(blockedCount - 1);

Lobs_dB = min(max(Lobs_dB, 0), maxExtraLoss_dB);
end

function polys = loadPolygonShapefile(shpFile, defaultHeight, readHeight)
S = shaperead(shpFile, 'UseGeoCoords', true);

polys = struct('Lat', {}, 'Lon', {}, 'H', {});
idx = 0;

for i = 1:numel(S)
    [latParts, lonParts] = splitNaNParts(S(i).Lat, S(i).Lon);

    h = defaultHeight;

    if readHeight
        h = inferHeightFromShape(S(i), defaultHeight);
    end

    for p = 1:numel(latParts)
        latp = latParts{p};
        lonp = lonParts{p};

        if numel(latp) < 3 || numel(lonp) < 3
            continue;
        end

        idx = idx + 1;
        polys(idx).Lat = latp(:)';
        polys(idx).Lon = lonp(:)';
        polys(idx).H = h;
    end
end
end

function h = inferHeightFromShape(s, defaultHeight)
h = defaultHeight;

candidateFields = {'HEIGHT','height','HGT','hgt','ALTURA','altura','BUILD_H','build_h', ...
                   'LEVELS','levels','NUM_FLOOR','num_floor','PISOS','pisos'};

for i = 1:numel(candidateFields)
    fn = candidateFields{i};

    if isfield(s, fn)
        v = s.(fn);
        numv = str2doubleSafe(v);

        if ~isnan(numv) && numv > 0
            if contains(lower(fn), 'level') || contains(lower(fn), 'floor') || contains(lower(fn), 'piso')
                h = max(3*numv, defaultHeight);
            else
                h = numv;
            end

            return;
        end
    end
end
end

function x = str2doubleSafe(v)
if isnumeric(v)
    x = double(v);
    return;
end

if isstring(v) || ischar(v)
    x = str2double(v);
    return;
end

x = NaN;
end

function [latParts, lonParts] = splitNaNParts(lat, lon)
nanMask = isnan(lat) | isnan(lon);

if ~any(nanMask)
    latParts = {lat(:)'};
    lonParts = {lon(:)'};
    return;
end

idx = find(nanMask);
cuts = [0, idx(:)', numel(lat)+1];

latParts = {};
lonParts = {};

for i = 1:numel(cuts)-1
    a = cuts(i) + 1;
    b = cuts(i+1) - 1;

    if b >= a
        latParts{end+1} = lat(a:b);
        lonParts{end+1} = lon(a:b);
    end
end
end

function Zout = fillMissingNearest2D(Zin)
mask = ~isnan(Zin);

if all(mask(:))
    Zout = Zin;
    return;
end

[rows, cols] = size(Zin);
[Xg, Yg] = meshgrid(1:cols, 1:rows);

xKnown = Xg(mask);
yKnown = Yg(mask);
zKnown = Zin(mask);

Zout = Zin;

if isempty(zKnown)
    Zout(:) = 0;
    return;
end

Zout(~mask) = griddata(xKnown, yKnown, zKnown, Xg(~mask), Yg(~mask), 'nearest');

remaining = isnan(Zout);

if any(remaining(:))
    Zout(remaining) = min(zKnown);
end
end

function Zs = smoothGrid2DNaN(Z, sigma)
if sigma <= 0
    Zs = Z;
    return;
end

valid = ~isnan(Z);

if ~any(valid(:))
    Zs = Z;
    return;
end

Z0 = Z;
Z0(~valid) = 0;
W = double(valid);

try
    Znum = imgaussfilt(Z0, sigma, 'Padding', 'replicate');
    Zden = imgaussfilt(W, sigma, 'Padding', 'replicate');
catch
    hsize = max(3, 2*ceil(3*sigma)+1);
    g = localGaussianKernel(hsize, sigma);
    Znum = conv2(Z0, g, 'same');
    Zden = conv2(W, g, 'same');
end

Zs = Znum ./ max(Zden, eps);
Zs(Zden <= 0.05) = NaN;
end

function G = localGaussianKernel(hsize, sigma)
c = (hsize - 1)/2;
[X, Y] = meshgrid(-c:c);

G = exp(-(X.^2 + Y.^2)/(2*sigma^2));
G = G / sum(G(:));
end
