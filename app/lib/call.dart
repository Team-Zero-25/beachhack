import 'dart:async';

import 'package:direct_caller_sim_choice/direct_caller_sim_choice.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart'; //
import 'package:slider_button/slider_button.dart';
import 'home.dart';

class Call extends StatefulWidget {
  const Call({super.key});

  @override
  State<Call> createState() => _CallState();
}

class _CallState extends State<Call> {
  int _countdown = 10;
  bool _isCalling = false;
  bool _callEnded = false;
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _makeCall();
      }
    });
  }

  Future<void> _makeCall() async {
    if (!mounted) return;
    setState(() {
      _isCalling = true;
      _callEnded = false;
    });

    var status = await Permission.phone.request();
    if (status.isGranted) {
      String? officerPhone = SosAcknowledgmentData().officerPhone;
      try {
        await DirectCaller().makePhoneCall(officerPhone!);
      } catch (e) {
        print("Error making call: $e");
      }

      // 🔥 Listen for call state
      PhoneState.stream.listen((event) {
        if (event.status == PhoneStateStatus.CALL_ENDED) {
          setState(() {
            _isCalling = false;
            _callEnded = true;
          });
        }
      });
    } else {
      print("CALL_PHONE permission denied!");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? officerName = SosAcknowledgmentData().officerName;
    return Scaffold(
      backgroundColor: const Color(0xFFED3B3B),
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.black,
        backgroundColor: Colors.transparent,
        leading: BackButtonWidget(context, Colors.black),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Calling $officerName',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _callEnded
                    ? 'Call Ended'
                    : _isCalling
                        ? 'Call in Progress...'
                        : 'Calling in $_countdown sec',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildText('S'),
                  buildText('O'),
                  buildText('S'),
                ],
              ),
              const SizedBox(height: 30),
              _callEnded ? PillButton(context) : buildSliderButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget PillButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
        ),
        child: Text(
          "OK",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildSliderButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: 280,
        height: 65,
        child: SliderButton(
          action: () async {
            if (_isCalling) return false;
            _timer?.cancel();
            Navigator.pop(context);
            return true;
          },
          alignLabel: Alignment.center,
          shimmer: true,
          // 🔥 Restores glowing effect
          label: Text(
            _isCalling ? "Call in Progress" : "Slide to Cancel",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
          icon: const Icon(
            Icons.call_end,
            color: Colors.red,
          ),
          buttonColor: Colors.white,
          backgroundColor: Colors.black,
          baseColor: Colors.red,
        ),
      ),
    );
  }

  Text buildText(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.archivoBlack(
        fontSize: 150,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: -5,
        height: 1.2,
      ),
    );
  }

  IconButton BackButtonWidget(BuildContext context, Color color) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          color: color,
        ),
      ),
      onPressed: () {
        if (!_isCalling) {
          _timer?.cancel();
          Navigator.pop(context);
        }
      },
    );
  }
}
