from setuptools import setup, find_packages

setup(
    name='sugarpidisplay',
    version='1.0.0',
    description='Display your CGM data on a Waveshare e-paper display',
    url='https://github.com/robertrub/SugarPiDisplay',
    author='Bryan Bassett',
    license='MIT',
    packages=find_packages(),
    python_requires='>=3.8',
    install_requires=[
        'Flask>=2.3.0',
        'Flask-WTF>=1.1.0',
        'Pillow>=10.0.0',
        'spidev>=3.6',
        'RPi.GPIO>=0.7.0',
        'requests>=2.31.0',
    ],
    zip_safe=False
)
