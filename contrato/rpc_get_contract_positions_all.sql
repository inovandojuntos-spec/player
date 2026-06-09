\safetynotice
{images/warning.pdf}
{The lubrication system is critical for the operation of oil-flooded screw compressors. Failure or inadequate performance of the lubrication system may result in severe compressor damage.}

The liquefaction unit (UNIT 350) is equipped with local control panels associated with each mixed refrigerant compressor package (PK-351-1/2/3/4/5/6).

Each local control panel allows the operator to select the operating mode (Local or Remote) for both the LP compressor (C-351L-x) and the HP compressor (C-351H-x) by means of selector switches:

\begin{itemize}
\item \textbf{Remote mode}: start and stop commands are issued from the Process Control System (PCS).
\item \textbf{Local mode}: the LP and HP compressors can be operated directly from the local control panel.
\end{itemize}

When Local mode is selected, dedicated \textbf{START} and \textbf{STOP} pushbuttons are provided for both the LP and HP compressors. These pushbuttons allow the operator to independently initiate the normal start-up and shutdown sequences of each compressor.

A dedicated Emergency Shutdown (ESD/LSD) pushbutton is also provided on the panel. Activation of this pushbutton initiates a local shutdown of the compressor package in accordance with the Cause & Effect Matrix.

The panel includes status indications for both compressors, including:

\begin{itemize}
\item \textbf{Running} status
\item \textbf{Ready to Start} indication
\item \textbf{Alarm / Trip} indication
\end{itemize}

These indications provide the operator with real-time feedback on the availability and operating condition of the LP and HP compressors, ensuring safe interaction between local operation and PCS supervision.


\begin{figure}[H]
\centering

\begin{subfigure}[b]{0.75\textwidth}
    \centering
    \includegraphics[width=\textwidth]{images/P-PN-PK-351-1.pdf}
    
    \label{fig:pk-351_layout}
\end{subfigure}
\hfill
\begin{subfigure}[b]{0.65\textwidth}
    \centering
    \includegraphics[width=\textwidth]{images/P-PN-PK-350.JPG}
   
    \label{fig:pk-351_pic}
\end{subfigure}

\caption{MR compressor local control panel}
\label{fig:pk-351_panel}

\end{figure}



{\footnotesize
\begin{xltabular}{\textwidth}{|L{0.15\textwidth}
|L{0.28\textwidth}
|Y|}

\caption{MR Compressor package local panel components}
\label{tab:compressor_panel_components} \\

\hline
\textbf{TAG} &
\textbf{SIGNAL} &
\textbf{DESCRIPTION} \\
\hline
\endfirsthead

\hline
\textbf{TAG} &
\textbf{SIGNAL} &
\textbf{DESCRIPTION} \\
\hline
\endhead

\hline
\endfoot

\hline
\endlastfoot


HS-3411.x-LR & LOCAL REMOTE SELECTOR & Select local remote control\\
HS-3411.x-ST & LOCAL START & Local start command\\
HS-3411.x-TP & LOCAL STOP & Local stop command\\
HS-3411.x-LSD & LOCAL SHUTDOWN & Local emergency shutdown \\
XL-3411.x-RU & RUN & Compressor running \\
XL-3411.x-RE & READY & Compressor ready to run\\
XL-3411.x-AL & ALARM & Compressor alarm or trip active\\


\end{xltabular}
}

\subsection{Ammonia Refrigeration Loop R1}

The ammonia refrigeration system (R1 loop – UNIT 340) operates as a closed-loop single-stage mechanical refrigeration cycle providing cooling duty to process users.

The refrigerant vapor returning from the cooling users is routed to the suction of the ammonia compressor packages (PK-341-1/2/3/4), where it is compressed to the required condensing pressure.

The compressed ammonia is then directed to the air-cooled condensers (E-342), where heat is rejected to ambient air and the refrigerant is condensed. The condensed liquid ammonia is collected in the liquid receiver (V-343), which ensures stable liquid inventory and distribution to the refrigeration users.

From the receiver, liquid ammonia is supplied to the following cooling consumers:

\begin{itemize}
\item E-311 – Natural Gas Precooler (UNIT 310)
\item E-354 – Mixed Refrigerant Cooler (UNIT 350)
\end{itemize}

At each user, the refrigerant flow is controlled by a level control valve (e.g. LV-3111, LV-3540), where the liquid ammonia expands from condensing pressure to evaporating pressure, generating the refrigeration effect.

The two-phase ammonia mixture is accumulated in the shell side of each exchanger, where evaporation occurs. The refrigerant level is controlled to ensure proper heat transfer and to avoid liquid carryover to the compressor suction.

A back-pressure control valve (PCV-3101) is installed on the E-311 circuit to maintain a higher evaporating pressure compared to E-354, preventing excessively low temperatures and minimizing the risk of hydrate formation in the natural gas stream.

The vaporized ammonia from all users is collected in a common suction header and returned to the compressors, completing the refrigeration cycle.

\clearpage

% Cambiamos TAMAÑO Y ORIENTACIÓN del papel
\KOMAoptions{
  paper=A3,
  paper=landscape,
  pagesize,
  DIV=20
}
\recalctypearea

\begin{figure}[h!]
  \centering
  \includegraphics[keepaspectratio, scale=0.42]{images/PRO10-ING-PR07.pdf}
  \caption{Unit 340 – Ammonia Refrigeration Loop (R1)}
\end{figure}

\clearpage
\KOMAoptions{
  paper=A4,
  paper=portrait,
  pagesize,
  DIV=12
}
\recalctypearea

\subsection{Natural Gas Precooler Level Control LIC-3111}

The natural gas precooler (E-311) operates as a flooded shell-and-tube exchanger using ammonia as refrigerant on the shell side. The liquid level is controlled by LIC-3111 through the ammonia inlet control valve (LV-3111).

The control objective is to maintain sufficient liquid inventory to ensure proper heat transfer while preventing liquid carryover to the compressor suction.

Normal operating level is 35\%, with a high level alarm at 41\%.

Low level may reduce cooling efficiency, while high level increases the risk of liquid entrainment, which can lead to compressor damage.

\vspace{0.5cm}

\begin{figure}[H]
\centering
\includegraphics[width=0.85\textwidth]{images/E-311.pdf}
\caption{Natural Gas Precooler E-311}
\label{fig:E311}
\end{figure}

\subsection{Ammonia MR Cooler Level Control LIC-3540}

The ammonia MR cooler operates as a flooded shell-and-tube heat exchanger, where liquid ammonia evaporates on the shell side to provide cooling to the mixed refrigerant.

The refrigerant level is controlled by LIC-3540 through the ammonia inlet control valve (LV-3540), maintaining adequate liquid inventory for stable heat transfer.

Normal operating level is 90\%.

Low level may reduce cooling performance, while excessive level increases the risk of liquid carryover toward the compressor suction.

\vspace{0.5cm}

\begin{figure}[H]
\centering
\includegraphics[width=0.85\textwidth]{images/E-354.pdf}
\caption{Ammonia MR Cooler}
\label{fig:E354}
\end{figure}


\subsection{Lube Oil System}

The lubrication oil system of the ammonia compressor packages (PK-341-1/2/3/4) is a critical subsystem designed to ensure reliable compressor operation by providing lubrication, cooling, and sealing functions.


\begin{figure}[H]
\centering
\includegraphics[width=0.95\textwidth]{images/PK-340-lube.pdf}
\caption{Ammonia compressor lube oil system}
\label{fig:lube_oil_system}
\end{figure}


\textbf{System Description}

The lube oil system performs the following main functions:

\begin{itemize}
\item Removal of heat generated during the compression process.
\item Lubrication of bearings and moving components.
\item Sealing between compressor rotors to improve compression efficiency.
\end{itemize}

During operation, the lube oil is injected into the compressor together with the refrigerant gas. The oil-gas mixture is discharged from the compressor and routed to the oil separator (V-341-1), where the oil is separated and collected.

The oil separator also serves as the oil reservoir for the system, ensuring adequate oil inventory during operation.

From the separator, the oil is circulated back to the compressor through the lube oil circuit.

\textbf{Oil Circulation and Conditioning}

The oil circulation system includes the following main equipment:

\begin{itemize}
\item \textbf{Oil Pump (P-341-1):} Positive displacement gear type pump (1 x 100\%), supplying pressurized oil to the compressor.
\item \textbf{Oil Cooler (E-341-1):} Removes heat from the oil to maintain proper viscosity and cooling performance.
\item \textbf{Oil Filters (F-341-1A/B):} Duplex configuration (1 operating + 1 standby) allowing continuous operation during filter replacement and ensuring clean oil supply.
\end{itemize}

Oil is pumped from the separator through the cooler and filters before being injected into the compressor for lubrication and capacity control functions.

\textbf{Control and Protection}

The lubrication system is monitored and protected by the control system through key parameters:

\begin{itemize}
\item Oil differential pressure across the compressor.
\item Oil temperature downstream of the cooler.
\item Oil level in the separator.
\end{itemize}

A minimum oil differential pressure is required to ensure proper lubrication. If the oil differential pressure drops below 1.5 bar, the compressor start sequence is inhibited or the running compressor is tripped.

This protection is critical to avoid damage to bearings, rotors, and internal components.

\textbf{Operational Considerations}

\begin{itemize}
\item The oil pump must be in operation prior to compressor start-up.
\item Oil temperature shall be within the specified range before loading the compressor.
\item Filters shall be monitored and replaced when differential pressure increases.
\item Stable oil pressure and temperature are required for proper slide valve operation.
\end{itemize}


\safetynotice
{images/warning.pdf}
{The oil pump is equipped with a magnetic coupling generating a strong magnetic field.

Personnel with implanted medical devices (e.g. pacemakers) shall not approach the equipment.

Maintain a safe distance from the magnetic coupling and avoid placing magnetic or sensitive electronic devices nearby.}

\subsection{Magnetic Coupling}

The lube oil pump (P-341-1) is equipped with a magnetic coupling, which transmits torque from the motor to the pump without a direct mechanical shaft connection. This design eliminates the need for dynamic seals and ensures leak-free operation, which is particularly suitable for ammonia service.


\begin{figure}[H]
\centering
\includegraphics[width=0.8\textwidth]{images/magnetic_coupling.pdf}
\caption{Oil pump magnetic coupling}
\label{fig:magnetic_coupling}
\end{figure}


The magnetic coupling consists of an outer rotor connected to the motor shaft and an inner rotor connected to the pump shaft. Torque is transmitted through magnetic forces across a containment shell, allowing complete separation between the driven and driving components.

This configuration provides several advantages, including improved reliability, reduced maintenance requirements, and elimination of potential leakage points. It is particularly suitable for hazardous fluids, as it minimizes the risk of external release.

Operationally, the magnetic coupling has a maximum torque transmission limit. In case of overload, magnetic decoupling may occur, resulting in the pump rotating without effective torque transmission. This condition may lead to loss of oil circulation and must be detected promptly. Dry running conditions shall be strictly avoided, as they can damage internal pump components.


\subsection{Compressor Start-Up Permissives}

Before initiating the automatic start-up sequence of any ammonia compressor package in Unit 340, the following start-up permissives shall be confirmed:

\begin{itemize}
\item All compressor motors to be available in \textbf{AUTO MODE} (typically three duty compressors available, with one package in standby).
\item All lube oil pumps to be available in \textbf{AUTO MODE}.
\item All oil cooler fans to be available in \textbf{AUTO MODE}.
\item Compressor capacity control / slide valve to be in \textbf{AUTO MODE}.
\item Compressor suction and discharge isolation valves to be confirmed \textbf{open}.
\item Lube oil temperature to be within the normal start-up range.
\item Compressor to be in \textbf{unloaded condition} before start.
\item Associated solenoid valves to be in their normal \textbf{AUTO MODE}.
\item No active shutdowns, trips, or critical alarms present on the selected package.
\item Motor restart inhibit / cool-down timer to be expired.
\end{itemize}

These permissives are intended to ensure that the compressor starts under safe mechanical and process conditions, with the lubrication system, cooling system, and capacity control system available before the motor is energized. This is consistent with the Unit 340 refrigeration package configuration and with the plant shutdown and safety philosophy for package operation.

\subsection{Compressor Start-Up Sequence}

After completion of the refrigeration system preparation and verification of permissive conditions, the ammonia compressor package can be started following the automatic sequence controlled by the PCS.

{\footnotesize
\begin{xltabular}{\textwidth}{
|C{0.055\textwidth}
|L{0.140\textwidth}
|C{0.075\textwidth}
|C{0.060\textwidth}
|C{0.080\textwidth}
|Y|}

\caption{Ammonia compressor start-up procedure}
\label{tab:compressor_startup_proc} \\

\hline

\textbf{Step} &
\textbf{Tag} &
\multicolumn{2}{c|}{\textbf{SP}} &
\textbf{Action} &
\textbf{Description} \\
\cline{3-4}

& & \textbf{Value} & \textbf{Unit} & & \\
\hline
\endfirsthead

\hline

\textbf{Step} &
\textbf{Tag} &
\multicolumn{2}{c|}{\textbf{SP}} &
\textbf{Action} &
\textbf{Description} \\
\cline{3-4}

& & \textbf{Value} & \textbf{Unit} & & \\
\hline
\endhead

\hline
\endfoot

\hline
\endlastfoot

1  & HS-3411.x-ST  & -- & -- & OC & Start automatic sequence by local panel or PCS\\

2  & P-341-x  & -- & -- & \ON SC & System command START auxiliary oil pump to establish lubrication flow. \\

3  & PDI-3414.x  & 1.5 & barg & \ON SC & System command CHECK oil differential pressure $\geq$ 1.5 barg before start permissive. \\

4  & ZT-3411.x  & <5 & \% & \ON SC & System command SET slide valve to fully unloaded position and confirm feedback. \\

5  & MC-341-x  & -- & -- & \ON SC & System command START compressor main motor and accelerate to nominal speed. \\

6  & --  & 30 & s & \ONA CK & Maintain compressor at minimum load for stabilization period. \\

7  & E-341-x  & -- & -- & \ON SC & System command START oil cooler fans to control oil temperature. \\

8 & PIC-3433.x  & -- & -- & \ON SC & System command ENABLE suction pressure and capacity control loops. \\

9 & -- & -- & -- & \ONA CK & Compressor reaches steady-state operation under automatic control. \\

\end{xltabular}
}

\subsection{Compressor Shutdown Sequence}

After confirmation of stable operating conditions and load reduction of the refrigeration system, the ammonia compressor package can be stopped following the automatic sequence controlled by the PCS.

{\footnotesize
\begin{xltabular}{\textwidth}{
|C{0.055\textwidth}
|L{0.140\textwidth}
|C{0.075\textwidth}
|C{0.060\textwidth}
|C{0.080\textwidth}
|Y|}

\caption{Ammonia compressor shutdown procedure}
\label{tab:compressor_shutdown_proc} \\

\hline

\textbf{Step} &
\textbf{Tag} &
\multicolumn{2}{c|}{\textbf{SP}} &
\textbf{Action} &
\textbf{Description} \\
\cline{3-4}

& & \textbf{Value} & \textbf{Unit} & & \\
\hline
\endfirsthead

\hline

\textbf{Step} &
\textbf{Tag} &
\multicolumn{2}{c|}{\textbf{SP}} &
\textbf{Action} &
\textbf{Description} \\
\cline{3-4}

& & \textbf{Value} & \textbf{Unit} & & \\
\hline
\endhead

\hline
\endfoot

\hline
\endlastfoot

1  & HS-3411.x-ST  & -- & -- & OC & Start automatic shutdown sequence by local panel or PCS. \\

2  & ZT-3411.x  & <5 & \% & \ON SC & System command SET slide valve to fully unloaded position and confirm feedback. \\

3  & MC-341-x  & -- & -- & \ON SC & System command STOP compressor main motor and confirm de-energization. \\

4  & P-341-x  & -- & -- & \ONA CK & Auxiliary oil pump remains running to ensure post-lubrication during coast-down. \\

5  & --  & 30 & s & \ONA CK & Maintain post-lubrication period to protect bearings and seals. \\

6  & PDI-3414.x  & -- & -- & \ONA CK & Monitor oil differential pressure decay and confirm safe lubrication conditions. \\

7  & P-341-x  & -- & -- & \ON SC & System command STOP auxiliary oil pump after post-lubrication period. \\

8  & MC-341-x  & -- & -- & \ONA CK & Confirm compressor fully stopped and no active start command present. \\

9  & PIC-3433.x  & -- & -- & \ON SC & System command DISABLE capacity control loops. \\

\end{xltabular}
}


