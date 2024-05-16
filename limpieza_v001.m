% Lee la imagen
img = imread("Imagenes\img2.jpg");

% Parámetros para líneas
con = 0.3; % Controla el contraste para obtener las líneas
Gauss = 1.1; % Controla el suavizado de las líneas

% Parámetros para sombras
porcentaje_suppix = 0.00005; % Controla la cantidad de superpíxeles por porcentaje (Valor entre 0 y 1)
SE_size = 30; % Tamaño del elemento estructurante

% Sombra
pixels = (size(img, 1) * size(img,2));
counts = imhist(img) / (3 * pixels);
tot = sum(counts);
perc = sum(counts(200:end));
if  perc < 0.75
    shadows = true;
else
    shadows = false;
end

% Calcula la cantidad de píxeles
pixeles = numel(img);

% Define el rango de contraste
LowCon = con - 0.000001;
HigCon = con + 0.000001;

% Convierte la imagen a escala de grises
imagen_gris = rgb2gray(img);

% Encuentra los bordes
bordes = edge(imagen_gris, 'sobel');

% Dilata los bordes
bordes_dilatados = imdilate(bordes, strel('disk', SE_size));

% Rellena los huecos que tocan el borde de la imagen
bordes_filled = imfill(bordes_dilatados, 'holes');

% Erode la máscara del objeto
mascara_objeto = imerode(bordes_filled, strel('disk', SE_size));

% Ajusta el contraste de la imagen
imgCon = imadjust(img, [LowCon, HigCon]);

% Aplica un filtro Gaussiano para suavizar las líneas
imgGau = imgaussfilt(imgCon, Gauss);

% Crea superpíxeles
[L, N] = superpixels(img, round(pixeles * porcentaje_suppix));

% Inicializa una matriz temporal para almacenar la suma ponderada de colores
imgSup = zeros(size(img), 'like', img);

% Obtener etiquetas de superpíxeles únicas
labels = unique(L);

% Iterar sobre las etiquetas de los superpíxeles
for labelVal = 1:numel(labels)
    % Obtener máscara para el superpíxel actual
    mask = L == labels(labelVal);
    
    % Calcular el color promedio de la región actual
    meanColor = mean(double(img(repmat(mask, [1, 1, size(img, 3)]))), [1, 2]);
    
    % Suma ponderada de colores para este superpíxel

    imgSup(:, :, 1) = double(imgSup(:, :, 1)) + meanColor .* double(mask);
    imgSup(:, :, 2) = double(imgSup(:, :, 2)) + meanColor .* double(mask);
    imgSup(:, :, 3) = double(imgSup(:, :, 3)) + meanColor .* double(mask);
end

% Aplica sombras si es necesario
if shadows
    imgCut = im2double(imgSup) .* im2double(mascara_objeto);
else
    imgCut = 255 * ones(size(imgSup), 'like', imgSup);
end

% Elimina el fondo negro si se aplican sombras
imgCut(imgCut == 0) = 255;

% Convierte las líneas a tipo double
imgLines = im2double(imgGau);

% Combina las líneas y las sombras
imgFinal = im2double(imgCut) .* imgLines;

% Muestra la imagen final
figure;
h_img = imshow(imgFinal);