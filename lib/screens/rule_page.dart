import 'package:flutter/material.dart';

import 'title_page.dart';

class RulePage extends StatelessWidget {
  const RulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const TitlePage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '【ルール説明】\n\n'
                    '・タップしたカードのカラー点数を獲得します。\n'
                    '・カラー点数が11点以上になるとゲーム終了です。\n'
                    '・カラー点数が10点ぴったりになるとスコアボーナス10を獲得し、カラー点数が5に戻ります。\n'
                    '・全てのカラー点数合計が20点になるとスコアボーナス100を獲得します。\n'
                    '・全てのカラー点数が9点になるとスコアボーナス999を獲得します。\n'
                    '・5ターンごとに好きなカラー点数を0に戻せます。\n\n'
                    '【特殊カード】\n'
                    '・紫カード：場の4枚を引き直します。\n'
                    '・黒UPカード：他の数字カードを1増加させます（5を超えません）。\n'
                    '・黒DOWNカード：他の数字カードを1減少させます（1未満になりません）。\n\n'
                    '【出現割合】\n'
                    '・数字カード20種（4色×1〜5）\n'
                    '・紫カード1種（場に2枚以上出現しません）\n'
                    '・黒UPカード1種\n'
                    '・黒DOWNカード1種\n',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}