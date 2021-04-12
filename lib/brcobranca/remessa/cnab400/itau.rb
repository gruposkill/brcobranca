# -*- encoding: utf-8 -*-
module Brcobranca
  module Remessa
    module Cnab400
      class Itau < Brcobranca::Remessa::Cnab400::Base
        VALOR_EM_REAIS = "1"
        VALOR_EM_PERCENTUAL = "2"

        validates_presence_of :agencia, :conta_corrente, message: 'não pode estar em branco.'
        validates_presence_of :documento_cedente, :digito_conta, message: 'não pode estar em branco.'
        validates_length_of :agencia, maximum: 4, message: 'deve ter 4 dígitos.'
        validates_length_of :conta_corrente, maximum: 5, message: 'deve ter 5 dígitos.'
        validates_length_of :documento_cedente, minimum: 11, maximum: 14, message: 'deve ter entre 11 e 14 dígitos.'
        validates_length_of :carteira, maximum: 3, message: 'deve ter no máximo 3 dígitos.'
        validates_length_of :digito_conta, maximum: 1, message: 'deve ter 1 dígito.'

        # Nova instancia do Itau
        def initialize(campos = {})
          campos = { aceite: 'N' }.merge!(campos)
          super(campos)
        end

        def agencia=(valor)
          @agencia = valor.to_s.rjust(4, '0') if valor
        end

        def conta_corrente=(valor)
          @conta_corrente = valor.to_s.rjust(5, '0') if valor
        end

        def carteira=(valor)
          @carteira = valor.to_s.rjust(3, '0') if valor
        end

        def cod_banco
          '341'
        end

        def nome_banco
          'BANCO ITAU SA'.ljust(15, ' ')
        end

        # Informacoes da conta corrente do cedente
        #
        # @return [String]
        #
        def info_conta
          # CAMPO            TAMANHO
          # agencia          4
          # complemento      2
          # conta corrente   5
          # digito da conta  1
          # complemento      8
          "#{agencia}00#{conta_corrente}#{digito_conta}#{''.rjust(8, ' ')}"
        end

        # Complemento do header
        # (no caso do Itau, sao apenas espacos em branco)
        #
        # @return [String]
        #
        def complemento
          ''.rjust(294, ' ')
        end

        # Codigo da carteira de acordo com a documentacao o Itau
        # se a carteira nao forem as testadas (150, 191 e 147)
        # retorna 'I' que é o codigo das carteiras restantes na documentacao
        #
        # @return [String]
        #
        def codigo_carteira
          return 'U' if carteira.to_s == '150'
          return '1' if carteira.to_s == '191'
          return 'E' if carteira.to_s == '147'
          'I'
        end

        # Detalhe do arquivo
        #
        # @param pagamento [PagamentoCnab400]
        #   objeto contendo as informacoes referentes ao boleto (valor, vencimento, cliente)
        # @param sequencial
        #   num. sequencial do registro no arquivo
        #
        # @return [String]
        #
        def monta_detalhe(pagamento, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

          detalhe = '1'                                                     # identificacao transacao               9[01] 001-001
          detalhe << Brcobranca::Util::Empresa.new(documento_cedente).tipo  # tipo de identificacao da empresa      9[02] 002-003
          detalhe << documento_cedente.to_s.rjust(14, '0')                  # cpf/cnpj da empresa                   9[14] 004-017
          detalhe << agencia                                                # agencia                               9[04] 018-021
          detalhe << ''.rjust(2, '0')                                       # complemento de registro (zeros)       9[02] 022-023
          detalhe << conta_corrente                                         # conta corrente                        9[05] 024-028
          detalhe << digito_conta                                           # dac                                   9[01] 029-029
          detalhe << ''.rjust(4, ' ')                                       # complemento do registro (brancos)     X[04] 030-033
          detalhe << ''.rjust(4, '0')                                       # codigo cancelamento (zeros)           9[04] 034-037
          detalhe << pagamento.documento_ou_numero.to_s.ljust(25)           # identificacao do tit. na empresa      X[25] 038-062
          detalhe << pagamento.nosso_numero.to_s.rjust(8, '0')              # nosso numero                          9[08] 063-070
          detalhe << ''.rjust(13, '0')                                      # quantidade de moeda variavel          9[13] 071-083
          detalhe << carteira                                               # carteira                              9[03] 084-086
          detalhe << ''.rjust(21, ' ')                                      # identificacao da operacao no banco    X[21] 087-107
          detalhe << codigo_carteira                                        # codigo da carteira                    X[01] 108-108
          detalhe << pagamento.identificacao_ocorrencia                     # identificacao ocorrencia              9[02] 109-110
          detalhe << pagamento.numero.to_s.rjust(10, '0')                   # numero do documento                   X[10] 111-120
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')           # data do vencimento                    9[06] 121-126
          detalhe << pagamento.formata_valor                                # valor do documento                    9[13] 127-139
          detalhe << cod_banco                                              # codigo banco                          9[03] 140-142
          detalhe << ''.rjust(5, '0')                                       # agencia cobradora - deixar zero       9[05] 143-147
          detalhe << '99'                                                   # especie  do titulo                    X[02] 148-149
          detalhe << pagamento.aceite || 'N'                                # aceite (A/N)                          X[01] 150-150
          detalhe << pagamento.data_emissao.strftime('%d%m%y')              # data de emissao                       9[06] 151-156
          detalhe << pagamento.cod_primeira_instrucao.to_s.rjust(2, '0')    # 1a instrucao - deixar zero            X[02] 157-158
          detalhe << pagamento.cod_segunda_instrucao.to_s.rjust(2, '0')     # 2a instrucao - deixar zero            X[02] 159-160
          detalhe << pagamento.formata_valor_mora                           # valor mora ao dia                     9[13] 161-173
          detalhe << pagamento.formata_data_desconto                        # data limite para desconto             9[06] 174-179
          detalhe << pagamento.formata_valor_desconto                       # valor do desconto                     9[13] 180-192
          detalhe << pagamento.formata_valor_iof                            # valor do iof                          9[13] 193-205
          detalhe << pagamento.formata_valor_abatimento                     # valor do abatimento                   9[13] 206-218
          detalhe << pagamento.identificacao_sacado                         # identificacao do pagador              9[02] 219-220
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0')         # documento do pagador                  9[14] 221-234
          detalhe << pagamento.nome_sacado.format_size(30)                  # nome do pagador                       X[30] 235-264
          detalhe << ''.rjust(10, ' ')                                      # complemento do registro (brancos)     X[10] 265-274
          detalhe << pagamento.endereco_sacado.format_size(40)              # endereco do pagador                   X[40] 275-314
          detalhe << pagamento.bairro_sacado.format_size(12)                # bairro do pagador                     X[12] 315-326
          detalhe << pagamento.cep_sacado                                   # cep do pagador                        9[08] 327-334
          detalhe << pagamento.cidade_sacado.format_size(15)                # cidade do pagador                     X[15] 335-349
          detalhe << pagamento.uf_sacado                                    # uf do pagador                         X[02] 350-351
          detalhe << pagamento.nome_avalista.format_size(30)                # nome do sacador/avalista              X[30] 352-381
          detalhe << ''.rjust(4, ' ')                                       # complemento do registro               X[04] 382-385
          detalhe << ''.rjust(6, '0')                                       # data da mora                          9[06] 386-391
          # detalhe << pagamento.data_mora ? (pagamento.data_mora.strftime('%d%m%y')) : (''.rjust(6, '0'))                                       # data da mora                          9[06] 386-391
          detalhe << prazo_instrucao(pagamento)                             # prazo para a instrução                9[02] 392-393
          detalhe << ''.rjust(1, ' ')                                       # complemento do registro (brancos)     X[01] 394-394
          detalhe << sequencial.to_s.rjust(6, '0')                          # numero do registro no arquivo         9[06] 395-400
          detalhe
        end

        def prazo_instrucao(pagamento)
          ##return '03' unless pagamento.cod_primeira_instrucao == '09'
          pagamento.dias_protesto.rjust(2, '0')
        end

        def monta_detalhe_multa(pagamento, sequencial)
          detalhe = '2'
          detalhe << pagamento.codigo_multa
          detalhe << pagamento.data_vencimento.strftime('%d%m%Y')
          detalhe << pagamento.formata_percentual_multa(13)
          detalhe << ''.rjust(371, ' ')
          detalhe << sequencial.to_s.rjust(6, '0')
          detalhe
        end
      end
    end
  end
end
