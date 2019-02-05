# Hang Glider Machine Learning Project

## Purpose

The intent is to develop a system which uses machine learning to provide flight path recommendations to hang glider pilots.
In particular, this involves identifying the course of action which leads to achieving the most effective thermal lift for sustaining flight.
To achieve this will likely involve both domain knowledge and analytics for feature generation, including quantifying and understanding the effect of glider characteristics, weather and atmosphere, and pilot characteristics and inputs.
A successful outcome would be to provide the pilot in-flight feedback through some means (such as an app) which recommends directions of travel that result in demonstrably longer flight times.

## Background

Hang gliders pilots (and others such as paraglider pilots) rely on several techniques to remain aloft while in free flight.
These include thermals, ridge lift, and convergence lift.

Thermals are rising columns or bubbles of air.
They are caused by solar radiation heating of the ground, which causes this air near the ground to become warmer.
Eventually, a mass of the warmer air breaks free, rising through the cooler air above, somewhat like a bubble rising in a lava lamp.
As the air rises, the rate of ascent increases due to the adiabatic lapse rate (atmospheric air tends to decrease about 2 degrees Celsius per 1000 ft whereas there is relatively little mixing within the thermal resulting in an increasing temperature differential), and they tend to grow in size.
The effects of thermals can be seen on days with white, fluffy, flat bottomed cumulus clouds.
These are caused by warmer thermal air (which can hold more moisture) being carried upwards into cooler regions.
Eventually the temperature drops below the dew point and the water vapour condenses forming a visible cloud.
However, absence of clouds does not mean there are no thermals.
In fact, strong thermals can form in a clear blue sky.

Thermals can be used to extend hang glider flights significantly.
The current straight-line distance record for a single flight in a hang glider is over 750 km.
The hang gliding sub-discipline of cross country flying involves alternatively rising on thermal columns to increase altitude and going on “glide” to achieve distance objectives (typically gps “waypoints”).
The best pilots in the world can achieve considerable average flight speeds using this method.
Finding effective thermal lift effectively is critical to both remaining aloft, and achieving distance objectives.

There are a number of ways that pilots locate thermals, and once located, the pilot “centers” the glider in the thermal and tries to maximize their lift by flying in circles within the thermal.

Locating thermals is a matter of theory, experience, and superstition.
Some common techniques are:

- [[insert later]]

Once a thermal is located, the pilot tries to maximize the lift.
Some considerations are:

- [[insert later]]

While centering in a thermal is largely a matter of experience and technique, the challenge is locating the thermals.
Unless there is physical evidence of a thermal (such as seeing another pilot successfully achieving lift), they are effectively invisible.

Further, since there is a large rising volume of air, there is also typically descending air, or “sink”, in the proximity of large thermals to fill in the displaced mass.
Even long flights can be cut short by searching for thermals and finding nothing but sink.

A system which improves the reliability of finding thermals would benefit both novice pilots (by extending their flights and experience) and advanced pilots (who may need to find elusive lift while travelling 100's of km's cross country).
Further, the predictions made by such a system may lead to insights and improve the understanding of thermal generation and development.

## Problem Statement

Based on information available during the flight, which direction should be flown to locate a thermal of sufficient strength to gain lift which can be used to materially extend flight time.

## Dataset

It is safe to say that most hang glider pilots fly with a variometer (or vario) on their glider.
Varios record GPS position to determine latitude and longitude (and sometimes altitude), and barometric pressure (which can be used to solve for altitude).
The varios are configured to emit audible tones based on changes in the rate of descent, emitting high pitched beeps when lift is encountered.
Often, the vario will connect to an airspeed sensor, which provides airspeed data.
However, the added airspeed data is less common than the positional data alone.

The primary dataset would be the recorded flights of hang glider pilots, as logged by their vario.
It is likely that most pilots retain their flight logs.
Further, the logs do not contain sensitive information that might make pilots uncomfortable with sharing the information (pilots routinely share vario files to validate their flights in competitions).

There are a number of limitations in the vario data, itemized below.

- Important values affecting flight characteristics, such as pilot hook-in weight, glider type, are not likely to be part of the log file, and even if they are, they are self-reported values.
- It would be useful to try to obtain this information to as high a degree of accuracy as possible.
- The time series resolution will vary, but it can be expected to be about one row of data per second.
- The vario is not aware of pilot inputs to the glider
- Airspeed will to be available for most of the data
- It may be difficult or impossible to determine actual bearing, since this is typically slightly different than the direction of travel in windy situations.
- Different Varios may not be equally reliable
- Novice pilot behaviour may be underrepresented in the data in terms of flight time recorded.
