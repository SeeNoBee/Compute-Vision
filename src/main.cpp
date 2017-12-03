#include <opencv2\opencv.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>

using namespace cv;
using namespace std;

int clamp(int value, int min, int max)
{
	return (value < min) ? min : ((value > max) ? max : value);
}

int main(int argc, char **argv)
{
	//парсинг аргументов
	if (argc < 5)
	{
		cout << "args: [path_to_image] [k] [blur_scale] [canny_threshold]" << endl;
		waitKey();
		return -1;
	}

	float k = atof(argv[2]);

	float blurScale = atof(argv[3]);
	if (blurScale < 0.f)
		blurScale = 0.02f;

	float cannyThreshold = atof(argv[4]);
	if (cannyThreshold <= 1.f)
		cannyThreshold = 35;

	//чтение картинки
	Mat source = imread(argv[1]);

	if (!source.data)
	{
		cout << "No image data" << endl;
		waitKey();
		return -1;
	}

	//отображение оригинала
	namedWindow("Source image", WINDOW_NORMAL);
	imshow("Source image", source);

	Mat source_gray;

	//ковертаци€ в чЄрно-белое изображение
	cvtColor(source, source_gray, CV_BGR2GRAY);

	//отображение чЄрно-белого изображени€
	namedWindow("Gray image", WINDOW_NORMAL);
	imshow("Gray image", source_gray);

	Mat blured;

	//размытие дл€ уменьшени€ шумов
	if ((int(source.cols * blurScale) > 0) && (int(source.rows * blurScale) > 0))
		blur(source_gray, blured, Size(source.cols * blurScale, source.rows * blurScale));
	else
		source_gray.copyTo(blured);

	//вычисление градиента
	Mat grad_x, grad_y;
	Mat abs_grad_x, abs_grad_y;
	Sobel(blured, grad_x, CV_16S, 1, 0);
	Sobel(blured, grad_y, CV_16S, 0, 1);

	convertScaleAbs(grad_x, abs_grad_x);
	convertScaleAbs(grad_y, abs_grad_y);

	Mat grad;

	addWeighted(abs_grad_x, 1.0, abs_grad_y, 1.0, 0, grad); //коэффициент смешивани€ единица, дл€ польшей €ркости результата

	//отображение градиента
	namedWindow("Gradient", WINDOW_NORMAL);
	imshow("Gradient", grad);

	Mat edges;

	//применение фильтра Canny
	Canny(blured, edges, 1, cannyThreshold);

	namedWindow("Canny", WINDOW_NORMAL);
	imshow("Canny", edges);

	Mat dist;

	//инверси€ изображени€ с рЄбрами дл€ корректного нахождени€ карты рассто€ний
	edges = 1 - edges;

	//нахождение карты рассто€ний
	distanceTransform(edges, dist, CV_DIST_L2, 3);

	Mat normDist;

	//нормализаци€ карты р€ссто€ний дл€ еЄ отображени€
	normalize(dist, normDist, 0, 1.0, NORM_MINMAX);

	//отображение карты рассто€ний
	namedWindow("Distance field", WINDOW_NORMAL);
	imshow("Distance field", normDist);

	Mat integralImage;

	//вычисление интегральньного изображени€
	integral(source, integralImage, CV_32F);

	Mat result = Mat(source.rows, source.cols, source.type());

	//финальна€ обработка
	for (int i = 0; i < source.cols; ++ i)
		for (int j = 0; j < source.rows; ++j)
		{
			int size = k * dist.at<float>(Point(i, j));
			if (size >= 1)
			{
				//подсчЄт количества пикселей, участвующих в свЄртке (с учЄтом выхода за край)
				int pixelsCount = ((clamp(i + size, 0, integralImage.cols - 1) - clamp(i - size, 0, integralImage.cols - 1)) *
					(clamp(j + size, 0, integralImage.rows - 1) - clamp(j - size, 0, integralImage.rows - 1)));

				//применение свЄртки
				result.at<Vec3b>(Point(i, j)) = (
					integralImage.at<Vec3f>(Point(clamp(i - size, 0, integralImage.cols - 1), clamp(j - size, 0, integralImage.rows - 1)))
					+ integralImage.at<Vec3f>(Point(clamp(i + size, 0, integralImage.cols - 1), clamp(j + size, 0, integralImage.rows - 1)))
					- integralImage.at<Vec3f>(Point(clamp(i - size, 0, integralImage.cols - 1), clamp(j + size, 0, integralImage.rows - 1)))
					- integralImage.at<Vec3f>(Point(clamp(i + size, 0, integralImage.cols - 1), clamp(j - size, 0, integralImage.rows - 1)))
					) / pixelsCount;
			}
			else
				result.at<Vec3b>(Point(i, j)) = source.at<Vec3b>(Point(i, j));
		}

	//отображение результата
	namedWindow("Result", WINDOW_NORMAL);
	imshow("Result", result);

	waitKey();
	return 0;
}