# -*- encoding: utf-8 -*-
module Brcobranca
  module Boleto
    class Hsbc < Base # Banco HSBC

      validates_inclusion_of :carteira, :in => %w( CNR ), :message => "não existente para este banco."
      validates_length_of :agencia, :maximum => 4, :message => "deve ser menor ou igual a 4 dígitos."
      validates_length_of :numero_documento, :maximum => 13, :message => "deve ser menor ou igual a 13 dígitos."
      validates_length_of :conta_corrente, :maximum => 7, :message => "deve ser menor ou igual a 7 dígitos."

      # Nova instancia do Hsbc
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos={})
        campos = {:carteira => "CNR"}.merge!(campos)
        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      def banco
        "399"
      end

      # Número seqüencial de 13 dígitos utilizado para identificar o boleto.
      # Número seqüencial de 7 dígitos utilizado para identificar o boleto.
      def numero_documento=(valor)
        @numero_documento = valor.to_s.rjust(13,'0') unless valor.nil?
      end

      # Número sequencial utilizado para distinguir os boletos na agência
      def nosso_numero
        if self.data_vencimento.kind_of?(Date)
          self.codigo_servico = "4"
          dia = self.data_vencimento.day.to_s.rjust(2,'0')
          mes = self.data_vencimento.month.to_s.rjust(2,'0')
          ano = self.data_vencimento.year.to_s[2..3]
          data = "#{dia}#{mes}#{ano}"

          parte_1 = "#{self.numero_documento}#{self.numero_documento.modulo11_9to2_10_como_zero}#{self.codigo_servico}"
          soma = parte_1.to_i + self.conta_corrente.to_i + data.to_i
          numero = "#{parte_1}#{soma.to_s.modulo11_9to2_10_como_zero}"
          numero
        else
          self.codigo_servico = "5"
          parte_1 = "#{self.numero_documento}#{self.numero_documento.modulo11_9to2_10_como_zero}#{self.codigo_servico}"
          soma = parte_1.to_i + self.conta_corrente.to_i
          numero = "#{parte_1}#{soma.to_s.modulo11_9to2_10_como_zero}"
          numero
        end
      end

      # Campo usado apenas na exibição no boleto
      #  Deverá ser sobreescrito para cada banco
      def nosso_numero_boleto
        self.nosso_numero
      end

      # Campo usado apenas na exibição no boleto
      #  Deverá ser sobreescrito para cada banco
      def agencia_conta_boleto
        self.conta_corrente
      end

      # Responsável por montar uma String com 43 caracteres que será usado na criação do código de barras
      def codigo_barras_segunda_parte
        # Montagem é baseada no tipo de carteira e na presença da data de vencimento
        if self.carteira == "CNR"
          dias_julianos = self.data_vencimento.to_juliano
          "#{self.conta_corrente}#{self.numero_documento}#{dias_julianos}2"
        end
      end

    end
  end
end