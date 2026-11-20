// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

class WeSayLogo extends StatelessWidget {
  final double size;
  const WeSayLogo({super.key, this.size = 128});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'WeSay',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF176B58),
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.forum_rounded,
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}
