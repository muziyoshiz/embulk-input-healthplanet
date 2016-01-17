# -*- coding: utf-8 -*-

module Embulk
  module Input
    module HealthplanetApi
      class Column

        def initialize(lang)
          case lang.downcase
          when 'ja', 'japanese'
            @names = {
              :time           => '測定日時',
              :model          => 'モデル',
              :weight         => '体重',
              :body_fat       => '体脂肪率',
              :muscle_mass    => '筋肉量',
              :muscle_score   => '筋肉スコア',
              :visceral_fat2  => '内臓脂肪レベル2',
              :visceral_fat1  => '内臓脂肪レベル1',
              :metabolic_rate => '基礎代謝量',
              :metabolic_age  => '体内年齢',
              :bone_mass      => '推定骨量',
            }
          when 'en', 'english'
            @names = {
              :time           => 'time',
              :model          => 'model',
              :weight         => 'weight',
              :body_fat       => 'body fat %',
              :muscle_mass    => 'muscle mass',
              :muscle_score   => 'muscle score',
              :visceral_fat2  => 'visceral fat level 2',
              :visceral_fat1  => 'visceral fat level 1',
              :metabolic_rate => 'basal metabolic rate',
              :metabolic_age  => 'metabolic age',
              :bone_mass      => 'estimated bone mass',
            }
          else
            # returns as-is API tag
            @names = {
              :time           => 'time',
              :model          => 'model',
              :weight         => '6021',
              :body_fat       => '6022',
              :muscle_mass    => '6023',
              :muscle_score   => '6024',
              :visceral_fat2  => '6025',
              :visceral_fat1  => '6026',
              :metabolic_rate => '6027',
              :metabolic_age  => '6028',
              :bone_mass      => '6029',
            }
          end
        end

        def name(key)
          @names[key]
        end
      end
    end
  end
end
