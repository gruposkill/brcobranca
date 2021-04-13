# Change Log

## 2021-04-13

Suporte para instruções de cobrança CNAB400 nos bancos 001, 033, 237 e 341

```
apt install nano
cd `bundle show brcobranca`

nano +110 lib/brcobranca/remessa/cnab400/bradesco.rb
pagamento.cod_primeira_instrucao.to_s.rjust(2, '0')
pagamento.cod_segunda_instrucao.to_s.rjust(2, '0')

nano +172 lib/brcobranca/remessa/cnab400/santander.rb
pagamento.cod_primeira_instrucao.to_s.rjust(2, '0')
pagamento.cod_segunda_instrucao.to_s.rjust(2, '0')

nano +115 lib/brcobranca/remessa/cnab400/itau.rb
pagamento.cod_primeira_instrucao.to_s.rjust(2, '0')
pagamento.cod_segunda_instrucao.to_s.rjust(2, '0')

nano +141 lib/brcobranca/remessa/cnab400/itau.rb
#

nano +133 lib/brcobranca/remessa/cnab400/itau.rb
pagamento.data_mora.strftime('%d%m%y')

nano +133 lib/brcobranca/remessa/cnab400/banco_brasil.rb
pagamento.cod_primeira_instrucao.to_s.rjust(2, '0')
pagamento.cod_segunda_instrucao.to_s.rjust(2, '0')

kill -USR2  $(ps aux | grep '9292' | awk '{print $2}')
```
