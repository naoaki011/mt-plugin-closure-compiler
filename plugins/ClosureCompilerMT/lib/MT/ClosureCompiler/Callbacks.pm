package MT::ClosureCompiler::Callbacks;
use strict;

sub build_file
{
	my ($eh, %args) = @_;
	unless ($args{FileInfo}->url =~ m/.js$/) { return; }


	my $plugin = MT->component('ClosureCompilerMT');
	my $comp_level = $plugin->get_config_value('closure_compiler_compiler_level', 'blog:' . $args{Blog}->id());
	my $browser = MT->new_ua();
	my $response = $browser->post('http://closure-compiler.appspot.com/compile', [
		'compilation_level' => $comp_level,
		'output_format' => 'text',
		'output_info' => 'compiled_code',
		'js_code' => ${$args{Content}}
	]);
	MT->log({
			message => sprintf('Compiled %s with Closure Compiler.<br/><br/>%s', $args{FileInfo}->url(), $args{File}),
			blog_id => $args{Blog}->id(),
			level => MT::Log::INFO()
		});
	${$args{Content}} = $response->{_content};
}

sub cms_pre_save_template
{
	my ($cb, $app, $obj) = @_;
	
	if ($app->param('process_with_closure_compiler'))
	{
		$obj->process_with_closure_compiler(1);
	}

	1;
}

sub edit_template_param
{
	my ($cb, $app, $param, $tmpl) = @_;
	unless ($param->{id} and $param->{type} eq 'index' and $param->{outfile} =~ m/.js$/) { return; }
	
	use MT::Template;
	my $template = MT::Template->load({ id => $app->param('id') });

	my $args = {};
	$args->{yn} = (defined $template->process_with_closure_compiler() ? $template->process_with_closure_compiler() : 0);
	my $newElement = $tmpl->createElement('ClosureCompilerTemplateEditorAddition', $args);
	my $oldElement = $tmpl->getElementById('identifier');
	$tmpl->insertAfter($newElement, $oldElement);
}

sub edit_template_cc_hdlr
{
	my ($ctx, $args) = @_;
	my $yn = $args->{yn} ? 'yes' : 'no';
	my $old = "id=\"process_with_closure_compiler_$yn\"";
        my $new = "$old checked=\"checked\"";

	my $text = <<TEXT;
	
<mtapp:setting
        id="process_with_closure_compiler"
        label="<__trans phrase="Process with Google Closure Compiler">">
            <input type="radio" name="process_with_closure_compiler" id="process_with_closure_compiler_yes" value="1" class="" mt:watch-change="1" /> Yes
                <br/>
            <input type="radio" name="process_with_closure_compiler" id="process_with_closure_compiler_no" value="0" class="" mt:watch-change="1" /> No
</mtapp:setting>
TEXT

	$text =~ s/$old/$new/;

	return $ctx->build($text);
}

1;

